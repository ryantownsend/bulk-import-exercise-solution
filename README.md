[![Ruby on Rails CI](https://github.com/ryantownsend/bulk-import-exercise/actions/workflows/rubyonrails.yml/badge.svg)](https://github.com/ryantownsend/bulk-import-exercise/actions/workflows/rubyonrails.yml)

# Bulk Import Exercise

This repository serves as a starting point for an exercise in optimising bulk/batch imports.

The initial implementation is rudimentary in that it works, but it is not remotely optimised.

There are functional tests covering the behaviour to ensure your changes do not break anything and performance tests to benchmark the speed at which imports occur and the memory utilised. These tests are configured to trigger on Github Actions, therefore it should be straight-forward to clone/fork the repository, make your changes and measure the outcome.

If you open one of the [workflow runs in Github Actions](https://github.com/ryantownsend/bulk-import-exercise/actions/workflows/rubyonrails.yml), you'll see there's a summary of the performance and memory consumption of the API.

If you'd prefer to run the test suite locally, you can do so with RSpec (`bundle exec rspec`) and the performance and memory summary will be output to `tmp/summary.md` instead.

## Features

The application is a simple database containing movies and their ratings. Each movie can have emails associated with it that are notified when it's updated.

## Data Diagrams

### Entity Relationships

```mermaid
erDiagram
  MovieImports
  Movies ||--o{ MovieNotifications : "have many"
```

### Database Schema

```mermaid
classDiagram
  class movies{
    +uuid id
    +text title
    +text description
    +decimal rating
    +text publishing_status
    +text[] subscriber_emails
    +datetime created_at
    +datetime updated_at
  }
  class movie_notifications{
    +uuid id
    +text email
    +uuid movie_id
    +datetime created_at
  }
  class movie_imports{
    +uuid id
    +jsonb entries
    +text[] errors
    +datetime created_at
    +datetime updated_at
    +datetime started_at
    +datetime finished_at
  }
```
