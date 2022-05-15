module ImportMovies
  UPSERT_QUERY_TEMPLATE = <<~SQL
    with movie_import_entries as (
      select
        row_number() over() as index,
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
        jsonb_to_recordset(movie_imports.entries) as t(
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
        entry_errors = coalesce(errors.messages, '{}')
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

  # processes the upserting of data contained in a bulk import
  # @param [Integer] movie_import_id
  def self.call(movie_import_id)
    ApplicationRecord.transaction do
      # mark the import as started
      MovieImport.where(id: movie_import_id).update_all("started_at = now()")

      # perform the upsert
      upserted_movie_ids = ApplicationRecord.connection.select_values(
        UPSERT_QUERY_TEMPLATE % { movie_import_id: movie_import_id }
      )

      # enqueue notifications
      AfterCommitEverywhere.after_commit do
        upserted_movie_ids.each do |id|
          EventStream.movie_updated(id)
        end
      end

      # mark the import as finished
      MovieImport.where(id: movie_import_id).update_all("finished_at = now()")
    end
  end
end
