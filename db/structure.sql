SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: movie_imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.movie_imports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entries jsonb NOT NULL,
    entry_errors text[] DEFAULT '{}'::text[] NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    started_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone
);


--
-- Name: movie_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.movie_notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email text NOT NULL,
    movie_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: movies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.movies (
    id uuid NOT NULL,
    title text NOT NULL,
    description text NOT NULL,
    rating numeric(2,1) NOT NULL,
    publishing_status text NOT NULL,
    subscriber_emails text[],
    created_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT now() NOT NULL,
    CONSTRAINT movies_publishing_status_check CHECK ((publishing_status = ANY (ARRAY['unpublished'::text, 'published'::text, 'archived'::text]))),
    CONSTRAINT movies_rating_check CHECK (((rating >= (1)::numeric) AND (rating <= (5)::numeric)))
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: movie_imports movie_imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movie_imports
    ADD CONSTRAINT movie_imports_pkey PRIMARY KEY (id);


--
-- Name: movie_notifications movie_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movie_notifications
    ADD CONSTRAINT movie_notifications_pkey PRIMARY KEY (id);


--
-- Name: movies movies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movies
    ADD CONSTRAINT movies_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: index_movie_notifications_on_movie_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_movie_notifications_on_movie_id ON public.movie_notifications USING btree (movie_id);


--
-- Name: index_movies_on_publishing_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_movies_on_publishing_status ON public.movies USING btree (publishing_status);


--
-- Name: movie_notifications fk_rails_d8ffef889a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movie_notifications
    ADD CONSTRAINT fk_rails_d8ffef889a FOREIGN KEY (movie_id) REFERENCES public.movies(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('1'),
('2'),
('3'),
('4'),
('5');


