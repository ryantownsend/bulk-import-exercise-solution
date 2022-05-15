class CreateMoviesTable < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL
      create table movies (
        -- we'll use external UUIDs as our unique primary key
        id uuid not null primary key,

        -- each move will have some simple data, e.g. title and description
        title text not null,
        description text not null,

        -- there's a rating that must be 1-5 but allowing 1 decimal place
        rating decimal(2,1) not null
          check (rating >= 1 and rating <= 5),

        -- publishing status reflects whether the movie is not yet live on the
        -- website (unpublished), actively live (published), or was previously
        -- live (archived)
        publishing_status text not null
          check (publishing_status in ('unpublished', 'published', 'archived')),

        -- an optional list of people (email addresses) who want to be notified
        -- about creation of this movie or any updates
        subscriber_emails text[],

        -- finally, we have the standard Rails timestamps for the record,
        -- except we store the current timestamp by default
        created_at timestamp(6) without time zone not null default now(),
        updated_at timestamp(6) without time zone not null default now()
      )
    SQL
  end

  def down
    execute "drop table if exists movies"
  end
end
