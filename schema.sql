--
-- PostgreSQL database dump
--

\restrict LgcaHNEpCzaTwiU7BF41TWWs0tGzsSXd4PlcSetckLqWXw8mgWW9Z8yOdA6N66i

-- Dumped from database version 18.3 (Homebrew)
-- Dumped by pg_dump version 18.6

-- Started on 2026-10-15 22:27:35 EEST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 867 (class 1247 OID 24734)
-- Name: email_domain; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.email_domain AS character varying(100)
	CONSTRAINT email_domain_check CHECK (((VALUE)::text ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text));


--
-- TOC entry 871 (class 1247 OID 24737)
-- Name: phone_domain; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.phone_domain AS character varying(20)
	CONSTRAINT phone_domain_check CHECK (((VALUE)::text ~ '^\+?[0-9\s\-\(\)]{7,20}$'::text));


--
-- TOC entry 875 (class 1247 OID 24740)
-- Name: price_domain; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.price_domain AS numeric(10,2)
	CONSTRAINT price_domain_check CHECK ((VALUE >= (0)::numeric));


--
-- TOC entry 879 (class 1247 OID 24743)
-- Name: sponsorship_level; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.sponsorship_level AS character varying(20)
	CONSTRAINT sponsorship_level_check CHECK (((VALUE)::text = ANY (ARRAY[('головний'::character varying)::text, ('преміальний'::character varying)::text, ('звичайний'::character varying)::text])));


--
-- TOC entry 244 (class 1255 OID 24745)
-- Name: buy_ticket(integer, integer, numeric, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.buy_ticket(IN p_user_id integer, IN p_event_id integer, IN p_price numeric, INOUT p_status text DEFAULT 'pending'::text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    uid ALIAS FOR p_user_id;
    min_price CONSTANT NUMERIC := 0;
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO STRICT v_count
    FROM event
    WHERE event_id = p_event_id;

    IF p_price < min_price THEN
        RAISE EXCEPTION 'Ціна не може бути від''ємною: %', p_price;
    END IF;

    INSERT INTO ticket(event_id, user_id, price, purchase_date)
    VALUES (p_event_id, uid, p_price, NOW());

    p_status := 'success';
    RAISE NOTICE 'Квиток куплено: користувач %, подія %, ціна %', uid, p_event_id, p_price;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_status := 'error';
        RAISE NOTICE 'Помилка: подію з id % не знайдено', p_event_id;
    WHEN OTHERS THEN
        p_status := 'error';
        RAISE NOTICE 'Помилка: %', SQLERRM;
END;
$$;


--
-- TOC entry 245 (class 1255 OID 24746)
-- Name: count_tickets_per_event(); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.count_tickets_per_event()
    LANGUAGE plpgsql
    AS $$
DECLARE
    rec RECORD;
    cur CURSOR FOR
        SELECT t.event_id, COUNT(*) AS total, e.name AS event_name
        FROM ticket t
        JOIN event e ON t.event_id = e.event_id
        GROUP BY t.event_id, e.name;
BEGIN
    OPEN cur;

    LOOP
        FETCH cur INTO rec;
        EXIT WHEN NOT FOUND;

        IF rec.total > 2 THEN
            RAISE NOTICE 'Подія "%" (id: %) має % квитків [БАГАТО]', rec.event_name, rec.event_id, rec.total;
        ELSE
            RAISE NOTICE 'Подія "%" (id: %) має % квитків', rec.event_name, rec.event_id, rec.total;
        END IF;
    END LOOP;

    CLOSE cur;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Помилка: %', SQLERRM;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 219 (class 1259 OID 24747)
-- Name: User; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."User" (
    user_id integer NOT NULL,
    name character varying(100) NOT NULL,
    email public.email_domain NOT NULL
);


--
-- TOC entry 220 (class 1259 OID 24755)
-- Name: User_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."User_user_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3938 (class 0 OID 0)
-- Dependencies: 220
-- Name: User_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."User_user_id_seq" OWNED BY public."User".user_id;


--
-- TOC entry 221 (class 1259 OID 24756)
-- Name: event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event (
    event_id integer NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    address character varying(300) NOT NULL,
    date_start timestamp without time zone NOT NULL,
    date_end timestamp without time zone NOT NULL,
    organizer_id integer NOT NULL,
    CONSTRAINT check_dates CHECK ((date_end > date_start)),
    CONSTRAINT event_name_check CHECK ((length(TRIM(BOTH FROM name)) > 0))
);


--
-- TOC entry 222 (class 1259 OID 24769)
-- Name: event_event_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.event_event_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3939 (class 0 OID 0)
-- Dependencies: 222
-- Name: event_event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.event_event_id_seq OWNED BY public.event.event_id;


--
-- TOC entry 223 (class 1259 OID 24770)
-- Name: event_sponsor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_sponsor (
    event_id integer NOT NULL,
    sponsor_id integer NOT NULL,
    level_of_sponsorship public.sponsorship_level NOT NULL
);


--
-- TOC entry 224 (class 1259 OID 24778)
-- Name: sponsor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sponsor (
    sponsor_id integer NOT NULL,
    name character varying(100) NOT NULL,
    email public.email_domain NOT NULL,
    number public.phone_domain
);


--
-- TOC entry 225 (class 1259 OID 24786)
-- Name: event_sponsors_info; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.event_sponsors_info AS
 SELECT e.event_id,
    e.name AS event_name,
    e.date_start,
    s.sponsor_id,
    s.name AS sponsor_name,
    s.email AS sponsor_email,
    s.number AS sponsor_phone,
    es.level_of_sponsorship
   FROM ((public.event e
     JOIN public.event_sponsor es ON ((e.event_id = es.event_id)))
     JOIN public.sponsor s ON ((es.sponsor_id = s.sponsor_id)))
  ORDER BY e.name, es.level_of_sponsorship
  WITH NO DATA;


--
-- TOC entry 226 (class 1259 OID 24793)
-- Name: ticket; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ticket (
    ticket_id integer CONSTRAINT ticket_tickt_id_not_null NOT NULL,
    event_id integer NOT NULL,
    user_id integer CONSTRAINT ticket_usir_id_not_null NOT NULL,
    price public.price_domain NOT NULL,
    purchase_date timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT ticket_date_check CHECK ((purchase_date <= now())),
    CONSTRAINT ticket_price_check CHECK (((price)::numeric >= (0)::numeric))
);


--
-- TOC entry 227 (class 1259 OID 24806)
-- Name: event_ticket_stats; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.event_ticket_stats AS
 SELECT e.event_id,
    e.name AS event_name,
    e.date_start,
    e.date_end,
    count(t.ticket_id) AS total_tickets,
    sum((t.price)::numeric) AS total_revenue,
    round(avg((t.price)::numeric), 2) AS avg_price
   FROM (public.event e
     LEFT JOIN public.ticket t ON ((e.event_id = t.event_id)))
  GROUP BY e.event_id, e.name, e.date_start, e.date_end;


--
-- TOC entry 228 (class 1259 OID 24811)
-- Name: organizer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizer (
    organizer_id integer NOT NULL,
    name character varying(100) NOT NULL,
    email public.email_domain NOT NULL,
    user_id integer NOT NULL
);


--
-- TOC entry 229 (class 1259 OID 24820)
-- Name: organizer_organizer_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organizer_organizer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3940 (class 0 OID 0)
-- Dependencies: 229
-- Name: organizer_organizer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.organizer_organizer_id_seq OWNED BY public.organizer.organizer_id;


--
-- TOC entry 230 (class 1259 OID 24821)
-- Name: public_users; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.public_users AS
 SELECT user_id,
    name
   FROM public."User"
  WITH LOCAL CHECK OPTION;


--
-- TOC entry 231 (class 1259 OID 24825)
-- Name: sponsor_sponsor_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sponsor_sponsor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3941 (class 0 OID 0)
-- Dependencies: 231
-- Name: sponsor_sponsor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sponsor_sponsor_id_seq OWNED BY public.sponsor.sponsor_id;


--
-- TOC entry 232 (class 1259 OID 24826)
-- Name: ticket_tickt_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ticket_tickt_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3942 (class 0 OID 0)
-- Dependencies: 232
-- Name: ticket_tickt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ticket_tickt_id_seq OWNED BY public.ticket.ticket_id;


--
-- TOC entry 3749 (class 2604 OID 24827)
-- Name: User user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."User" ALTER COLUMN user_id SET DEFAULT nextval('public."User_user_id_seq"'::regclass);


--
-- TOC entry 3750 (class 2604 OID 24828)
-- Name: event event_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event ALTER COLUMN event_id SET DEFAULT nextval('public.event_event_id_seq'::regclass);


--
-- TOC entry 3754 (class 2604 OID 24829)
-- Name: organizer organizer_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizer ALTER COLUMN organizer_id SET DEFAULT nextval('public.organizer_organizer_id_seq'::regclass);


--
-- TOC entry 3751 (class 2604 OID 24830)
-- Name: sponsor sponsor_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sponsor ALTER COLUMN sponsor_id SET DEFAULT nextval('public.sponsor_sponsor_id_seq'::regclass);


--
-- TOC entry 3752 (class 2604 OID 24831)
-- Name: ticket ticket_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket ALTER COLUMN ticket_id SET DEFAULT nextval('public.ticket_tickt_id_seq'::regclass);


--
-- TOC entry 3760 (class 2606 OID 24833)
-- Name: User User_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_pkey" PRIMARY KEY (user_id);


--
-- TOC entry 3764 (class 2606 OID 24835)
-- Name: event event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event
    ADD CONSTRAINT event_pkey PRIMARY KEY (event_id);


--
-- TOC entry 3766 (class 2606 OID 24837)
-- Name: event_sponsor event_sponsor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_sponsor
    ADD CONSTRAINT event_sponsor_pkey PRIMARY KEY (event_id, sponsor_id);


--
-- TOC entry 3774 (class 2606 OID 24839)
-- Name: organizer organizer_email_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizer
    ADD CONSTRAINT organizer_email_unique UNIQUE (email);


--
-- TOC entry 3776 (class 2606 OID 24841)
-- Name: organizer organizer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizer
    ADD CONSTRAINT organizer_pkey PRIMARY KEY (organizer_id);


--
-- TOC entry 3768 (class 2606 OID 24843)
-- Name: sponsor sponsor_email_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sponsor
    ADD CONSTRAINT sponsor_email_unique UNIQUE (email);


--
-- TOC entry 3770 (class 2606 OID 24845)
-- Name: sponsor sponsor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sponsor
    ADD CONSTRAINT sponsor_pkey PRIMARY KEY (sponsor_id);


--
-- TOC entry 3772 (class 2606 OID 24847)
-- Name: ticket ticket_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (ticket_id);


--
-- TOC entry 3762 (class 2606 OID 24849)
-- Name: User user_email_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT user_email_unique UNIQUE (email);


--
-- TOC entry 3777 (class 2606 OID 24850)
-- Name: event event_organizer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event
    ADD CONSTRAINT event_organizer_id_fkey FOREIGN KEY (organizer_id) REFERENCES public.organizer(organizer_id);


--
-- TOC entry 3778 (class 2606 OID 24855)
-- Name: event_sponsor event_sponsor_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_sponsor
    ADD CONSTRAINT event_sponsor_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.event(event_id);


--
-- TOC entry 3779 (class 2606 OID 24860)
-- Name: event_sponsor event_sponsor_sponsor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_sponsor
    ADD CONSTRAINT event_sponsor_sponsor_id_fkey FOREIGN KEY (sponsor_id) REFERENCES public.sponsor(sponsor_id);


--
-- TOC entry 3782 (class 2606 OID 24865)
-- Name: organizer fk_organizer_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizer
    ADD CONSTRAINT fk_organizer_user FOREIGN KEY (user_id) REFERENCES public."User"(user_id) ON DELETE CASCADE;


--
-- TOC entry 3780 (class 2606 OID 24870)
-- Name: ticket ticket_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.event(event_id);


--
-- TOC entry 3781 (class 2606 OID 24875)
-- Name: ticket ticket_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket
    ADD CONSTRAINT ticket_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."User"(user_id) ON DELETE CASCADE;


-- Completed on 2026-10-15 22:27:35 EEST

--
-- PostgreSQL database dump complete
--

\unrestrict LgcaHNEpCzaTwiU7BF41TWWs0tGzsSXd4PlcSetckLqWXw8mgWW9Z8yOdA6N66i

