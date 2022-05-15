module ImportMovies
  UPSERT_QUERY_TEMPLATE = <<~SQL
    with movie_import_entries as (
      select
      (row_number() over()) + %{batch_offset_start} as index,
        t.id,
        t.title,
        t.description,
        t.rating,
        t.published,
        t.subscriber_emails,
        movies.id is not null as already_exists,
        (
          (movies.id is not null or t.title is not null) and
          (movies.id is not null or t.description is not null) and
          (
            (movies.id is not null and (t.rating is null or t.rating between 1 and 5)) or
            (t.rating is not null and t.rating between 1 and 5)
          )
        ) as is_valid
      from
        movie_imports,
        jsonb_to_recordset(jsonb_path_query_array(movie_imports.entries, '$[%{batch_offset_start} to %{batch_offset_end}]')) as t(
          id uuid,
          title text,
          description text,
          rating numeric(2,1),
          published boolean,
          subscriber_emails text[]
        )
      left join
        movies on movies.id = t.id
      where
        movie_imports.id = '%{movie_import_id}'
    ),

    -- record our errors
    errored_entries as (
      update
        movie_imports
      set
        entry_errors = array_cat(coalesce(entry_errors, '{}'), coalesce(errors.messages, '{}'))
      from (
        select
          array_agg(t.message) as messages
        from
          (
            select
              unnest(
                array_remove(
                  array[
                    case when already_exists = false and title is null then 'Error with entry #' || index || ': Title cannot be blank' end,
                    case when already_exists = false and description is null then 'Error with entry #' || index || ': Description cannot be blank' end,
                    case when already_exists = false and rating is null then 'Error with entry #' || index || ': Rating cannot be blank' end,
                    case when rating is not null and rating not between 1 and 5 then 'Error with entry #' || index || ': Rating must be between 1 and 5' end
                  ],
                  null
                )
              ) as message
            from
              movie_import_entries
            where
              is_valid = false
          ) t
      ) errors
      where
        movie_imports.id = '%{movie_import_id}'
    ),

    -- where the movie doesn't exist, import it
    inserted_movies as (
      insert into
        movies (
          id,
          title,
          description,
          rating,
          publishing_status,
          subscriber_emails,
          created_at,
          updated_at
        )
      select
        movie_import_entries.id,
        movie_import_entries.title,
        movie_import_entries.description,
        movie_import_entries.rating,
        case
          when movie_import_entries.published = true then 'published'
          else 'unpublished'
        end,
        movie_import_entries.subscriber_emails,
        now() as created_at,
        now() as updated_at
      from
        movie_import_entries
      where
        movie_import_entries.already_exists = false and
        movie_import_entries.is_valid = true
      returning
        id
    ),

    -- where the movie does exist, update it, if it's actually going to change
    updated_movies as (
      update
        movies
      set
        title = coalesce(entries.title, movies.title),
        description = coalesce(entries.description, movies.description),
        rating = coalesce(entries.rating, movies.rating),
        publishing_status = case
          -- when published = null, no change
          when entries.published is null then movies.publishing_status
          -- when published = true, always set to published
          when entries.published = true then 'published'
          -- when published = false and current status is published, then archive
          when movies.publishing_status = 'published' then 'archived'
          -- when published = false and current status is unpublished, leave as unpublished
          else 'unpublished'
        end,
        subscriber_emails = coalesce(entries.subscriber_emails, movies.subscriber_emails),
        updated_at = now()
      from (
        select
          *
        from
          movie_import_entries
        where
          movie_import_entries.already_exists = true and
          movie_import_entries.is_valid = true
      ) entries
      where
        movies.id = entries.id and
        (
          movies.title is distinct from coalesce(entries.title, movies.title) or
          movies.description is distinct from coalesce(entries.description, movies.description) or
          movies.rating is distinct from coalesce(entries.rating, movies.rating) or
          movies.publishing_status is distinct from case
            -- when published = null, no change
            when entries.published is null then movies.publishing_status
            -- when published = true, always set to published
            when entries.published = true then 'published'
            -- when published = false and current status is published, then archive
            when movies.publishing_status = 'published' then 'archived'
            -- when published = false and current status is unpublished, leave as unpublished
            else 'unpublished'
          end or
          movies.subscriber_emails is distinct from coalesce(entries.subscriber_emails, movies.subscriber_emails)
        )
      returning
        movies.id
    )

    select
      id
    from
      inserted_movies

    union

    select
      id
    from
      updated_movies
  SQL

  MOVIE_IMPORT_BATCH_SIZE = ENV.fetch("MOVIE_IMPORT_BATCH_SIZE") { 10_000 }.to_i

   # processes the upserting of data contained in a bulk import
  # @param [Integer] movie_import_id
  def self.call(movie_import_id, batch_size: MOVIE_IMPORT_BATCH_SIZE)
    # unfortunately, Rails doesn't return generated columns on create
    # so we have to query for the entry_count manually, but we can
    # return it within the update to started_at below
    # mark the import as started and return the entry count
    entry_count = ApplicationRecord.connection.select_value <<~SQL
      update movie_imports
      set started_at = coalesce(started_at, now())
      where id = '#{movie_import_id}'
      returning entry_count
    SQL

    # calculate how many batches this movie has
    batch_count = (BigDecimal(entry_count) / batch_size).ceil
    # execute one update per batch
    0.upto(batch_count - 1) do |batch_index|
      import_batch(movie_import_id, batch_offset: batch_size * batch_index, batch_size: batch_size)
    end

    # mark the import as finished
    MovieImport.where(id: movie_import_id).update_all("finished_at = now()")
  end

  # Imports a subset of the movie import entries to ensure we don't have any
  # long running transactions keeping locks open
  # @param [Integer] movie_import_id
  # @param [Integer] batch_offset the record to start at
  # @param [Integer] batch_size how many records to process
  private_class_method def self.import_batch(movie_import_id, batch_offset:, batch_size:)
    ApplicationRecord.transaction do
      # perform the upsert
      upserted_movie_ids = ApplicationRecord.connection.select_values(UPSERT_QUERY_TEMPLATE % {
        movie_import_id: movie_import_id,
        batch_offset_start: batch_offset,
        batch_offset_end: batch_offset + batch_size
      })

      # enqueue notifications
      AfterCommitEverywhere.after_commit do
        upserted_movie_ids.each do |id|
          EventStream.movie_updated(id)
        end
      end
    end
  end
end
