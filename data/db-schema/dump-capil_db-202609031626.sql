--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5 (Debian 17.5-1.pgdg110+1)
-- Dumped by pg_dump version 17.0

-- Started on 2026-09-03 16:26:48

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
-- TOC entry 6 (class 2615 OID 22542)
-- Name: analytics; Type: SCHEMA; Schema: -; Owner: admin
--

CREATE SCHEMA analytics;


ALTER SCHEMA analytics OWNER TO admin;

--
-- TOC entry 4 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 3940 (class 0 OID 0)
-- Dependencies: 4
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 219 (class 1259 OID 22547)
-- Name: raw_a1_temp; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_a1_temp (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "K" character varying,
    "JK" character varying,
    "SD" character varying,
    "LMG" character varying,
    "No_" character varying,
    "SMA" character varying,
    "SMP" character varying,
    "Ver" character varying,
    "Code" character varying,
    "Utang" character varying,
    "Jur_S1" character varying,
    "Jur_S2" character varying,
    "Jur_S3" character varying,
    "Mentor" character varying,
    "Piutang" character varying,
    "Univ_S1" character varying,
    "Univ_S2" character varying,
    "Univ_S3" character varying,
    "Tabungan" character varying,
    "Th_Lahir" character varying,
    "Bln_Lahir" character varying,
    "Jur_D1_D4" character varying,
    "Pesantren" character varying,
    "Tgl_Lahir" character varying,
    "Gelar_Awal" character varying,
    "Univ_D1_D4" character varying,
    "Usia_Lahir" character varying,
    "Gelar_Akhir" character varying,
    "Status_Nikah" character varying,
    "Th_Integrasi" character varying,
    "Alamat_Negara" character varying,
    "Bln_Integrasi" character varying,
    "Tgl_Integrasi" character varying,
    "Usia_Integrasi" character varying,
    "Alamat_Provinsi" character varying,
    "Jenis_Pekerjaan" character varying,
    "Status_Tabungan" character varying,
    "Alamat_Kabupaten" character varying,
    "Alamat_Kecamatan" character varying,
    "Status_Aktivitas" character varying,
    "Jabatan_Pekerjaan" character varying,
    "Keahlian_Khusus_A" character varying,
    "Keahlian_Khusus_B" character varying,
    "Keahlian_Khusus_C" character varying,
    "Keahlian_Khusus_D" character varying,
    "Keahlian_Khusus_E" character varying,
    "Jenis_Pemberdayaan" character varying,
    "Status_Pemberdayaan" character varying,
    "Gaji_Rata_rata_Pekerjaan" character varying,
    "Aset_Hak_Milik_Mobil__Rp_" character varying,
    "Aset_Hak_Milik_Motor__Rp_" character varying,
    "Aset_Hak_Milik_Rumah__m2_" character varying,
    "Aset_Hak_Milik_Tanah__m2_" character varying
);


ALTER TABLE public.raw_a1_temp OWNER TO admin;

--
-- TOC entry 234 (class 1259 OID 168960)
-- Name: cleaned_user_area_a1; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.cleaned_user_area_a1 AS
 WITH latest_gen AS (
         SELECT max(raw_a1_temp._airbyte_generation_id) AS last_gen
           FROM public.raw_a1_temp
        )
 SELECT r."K",
    r."JK",
    r."LMG",
    r."Ver",
    r."Code",
    r."Tabungan",
    r."Status_Nikah",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Provinsi")::text) AS "Alamat_Provinsi",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Provinsi", ''::character varying))) AS normalized_provinsi,
    lower(TRIM(BOTH FROM regexp_replace((COALESCE(r."Alamat_Kabupaten", ''::character varying))::text, '^(kabupaten|kab|kab\.)\s*'::text, ''::text))) AS normalized_kabupaten,
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Kecamatan", ''::character varying))) AS normalized_kecamatan,
    regexp_replace((COALESCE(r."Code", ''::character varying))::text, '[^0-9\.]'::text, ''::text) AS cleaned_fullcode,
    'A1'::text AS kantor_id
   FROM (public.raw_a1_temp r
     JOIN latest_gen lg ON ((r._airbyte_generation_id = lg.last_gen)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.cleaned_user_area_a1 OWNER TO admin;

--
-- TOC entry 220 (class 1259 OID 22554)
-- Name: raw_a2; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_a2 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "K" character varying,
    "JK" character varying,
    "SD" character varying,
    "LMG" character varying,
    "No_" character varying,
    "SMA" character varying,
    "SMP" character varying,
    "Ver" character varying,
    "Code" character varying,
    "null" character varying,
    "Utang" character varying,
    "Jur_S1" character varying,
    "Jur_S2" character varying,
    "Jur_S3" character varying,
    "Mentor" character varying,
    "Piutang" character varying,
    "Univ_S1" character varying,
    "Univ_S2" character varying,
    "Univ_S3" character varying,
    "Tabungan" character varying,
    "Th_Lahir" character varying,
    "Bln_Lahir" character varying,
    "Jur_D1_D4" character varying,
    "Pesantren" character varying,
    "Tgl_Lahir" character varying,
    "Gelar_Awal" character varying,
    "Univ_D1_D4" character varying,
    "Usia_Lahir" character varying,
    "Gelar_Akhir" character varying,
    "Status_Nikah" character varying,
    "Th_Integrasi" character varying,
    "Alamat_Negara" character varying,
    "Bln_Integrasi" character varying,
    "Tgl_Integrasi" character varying,
    "Usia_Integrasi" character varying,
    "Alamat_Provinsi" character varying,
    "Jenis_Pekerjaan" character varying,
    "Status_Tabungan" character varying,
    "Alamat_Kabupaten" character varying,
    "Alamat_Kecamatan" character varying,
    "Status_Aktivitas" character varying,
    "Jabatan_Pekerjaan" character varying,
    "Keahlian_Khusus_A" character varying,
    "Keahlian_Khusus_B" character varying,
    "Keahlian_Khusus_C" character varying,
    "Keahlian_Khusus_D" character varying,
    "Keahlian_Khusus_E" character varying,
    "Jenis_Pemberdayaan" character varying,
    "Status_Pemberdayaan" character varying,
    "Gaji_Rata_rata_Pekerjaan" character varying,
    "Aset_Hak_Milik_Mobil__Rp_" character varying,
    "Aset_Hak_Milik_Motor__Rp_" character varying,
    "Aset_Hak_Milik_Rumah__m2_" character varying,
    "Aset_Hak_Milik_Tanah__m2_" character varying,
    "Instansi_Pekerjaan" character varying
);


ALTER TABLE public.raw_a2 OWNER TO admin;

--
-- TOC entry 236 (class 1259 OID 172025)
-- Name: cleaned_user_area_a2; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.cleaned_user_area_a2 AS
 WITH latest_gen AS (
         SELECT max(raw_a2._airbyte_generation_id) AS last_gen
           FROM public.raw_a2
        )
 SELECT r."K",
    r."JK",
    r."LMG",
    r."Ver",
    r."Code",
    r."Tabungan",
    r."Status_Nikah",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Provinsi")::text) AS "Alamat_Provinsi",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Provinsi", ''::character varying))) AS normalized_provinsi,
    lower(TRIM(BOTH FROM regexp_replace((COALESCE(r."Alamat_Kabupaten", ''::character varying))::text, '^(kabupaten|kab|kab\.)\s*'::text, ''::text))) AS normalized_kabupaten,
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Kecamatan", ''::character varying))) AS normalized_kecamatan,
    regexp_replace((COALESCE(r."Code", ''::character varying))::text, '[^0-9\.]'::text, ''::text) AS cleaned_fullcode,
    'A2'::text AS kantor_id
   FROM (public.raw_a2 r
     JOIN latest_gen lg ON ((r._airbyte_generation_id = lg.last_gen)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.cleaned_user_area_a2 OWNER TO admin;

--
-- TOC entry 221 (class 1259 OID 33140)
-- Name: raw_a3; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_a3 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "K" character varying,
    "JK" character varying,
    "SD" character varying,
    "LMG" character varying,
    "No_" character varying,
    "SMA" character varying,
    "SMP" character varying,
    "Ver" character varying,
    "Code" character varying,
    "null" character varying,
    "Utang" character varying,
    "Jur_S1" character varying,
    "Jur_S2" character varying,
    "Jur_S3" character varying,
    "Mentor" character varying,
    "Piutang" character varying,
    "Univ_S1" character varying,
    "Univ_S2" character varying,
    "Univ_S3" character varying,
    "Tabungan" character varying,
    "Th_Lahir" character varying,
    "Bln_Lahir" character varying,
    "Jur_D1_D4" character varying,
    "Pesantren" character varying,
    "Tgl_Lahir" character varying,
    "Gelar_Awal" character varying,
    "Univ_D1_D4" character varying,
    "Usia_Lahir" character varying,
    "Gelar_Akhir" character varying,
    "Status_Nikah" character varying,
    "Th_Integrasi" character varying,
    "Alamat_Negara" character varying,
    "Bln_Integrasi" character varying,
    "Tgl_Integrasi" character varying,
    "Usia_Integrasi" character varying,
    "Alamat_Provinsi" character varying,
    "Jenis_Pekerjaan" character varying,
    "Status_Tabungan" character varying,
    "Alamat_Kabupaten" character varying,
    "Alamat_Kecamatan" character varying,
    "Status_Aktivitas" character varying,
    "Jabatan_Pekerjaan" character varying,
    "Keahlian_Khusus_A" character varying,
    "Keahlian_Khusus_B" character varying,
    "Keahlian_Khusus_C" character varying,
    "Keahlian_Khusus_D" character varying,
    "Keahlian_Khusus_E" character varying,
    "Jenis_Pemberdayaan" character varying,
    "Status_Pemberdayaan" character varying,
    "Gaji_Rata_rata_Pekerjaan" character varying,
    "Aset_Hak_Milik_Mobil__Rp_" character varying,
    "Aset_Hak_Milik_Motor__Rp_" character varying,
    "Aset_Hak_Milik_Rumah__m2_" character varying,
    "Aset_Hak_Milik_Tanah__m2_" character varying,
    "Instansi_Pekerjaan" character varying
);


ALTER TABLE public.raw_a3 OWNER TO admin;

--
-- TOC entry 237 (class 1259 OID 172030)
-- Name: cleaned_user_area_a3; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.cleaned_user_area_a3 AS
 WITH latest_gen AS (
         SELECT max(raw_a3._airbyte_generation_id) AS last_gen
           FROM public.raw_a3
        )
 SELECT r."K",
    r."JK",
    r."LMG",
    r."Ver",
    r."Code",
    r."Tabungan",
    r."Status_Nikah",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Provinsi")::text) AS "Alamat_Provinsi",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Provinsi", ''::character varying))) AS normalized_provinsi,
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower(TRIM(BOTH FROM regexp_replace((COALESCE(r."Alamat_Kabupaten", ''::character varying))::text, '^(kabupaten|kab|kab\.)\s*'::text, ''::text))) AS normalized_kabupaten,
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Kecamatan", ''::character varying))) AS normalized_kecamatan,
    regexp_replace((COALESCE(r."Code", ''::character varying))::text, '[^0-9\.]'::text, ''::text) AS cleaned_fullcode,
    'A3'::text AS kantor_id
   FROM (public.raw_a3 r
     JOIN latest_gen lg ON ((r._airbyte_generation_id = lg.last_gen)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.cleaned_user_area_a3 OWNER TO admin;

--
-- TOC entry 222 (class 1259 OID 33159)
-- Name: raw_b1; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_b1 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "K" character varying,
    "JK" character varying,
    "SD" character varying,
    "LMG" character varying,
    "No_" character varying,
    "SMA" character varying,
    "SMP" character varying,
    "Ver" character varying,
    "Code" character varying,
    "null" character varying,
    "Utang" character varying,
    "Jur_S1" character varying,
    "Jur_S2" character varying,
    "Jur_S3" character varying,
    "Mentor" character varying,
    "Piutang" character varying,
    "Univ_S1" character varying,
    "Univ_S2" character varying,
    "Univ_S3" character varying,
    "Tabungan" character varying,
    "Th_Lahir" character varying,
    "Bln_Lahir" character varying,
    "Jur_D1_D4" character varying,
    "Pesantren" character varying,
    "Tgl_Lahir" character varying,
    "Gelar_Awal" character varying,
    "Univ_D1_D4" character varying,
    "Usia_Lahir" character varying,
    "Gelar_Akhir" character varying,
    "Status_Nikah" character varying,
    "Th_Integrasi" character varying,
    "Alamat_Negara" character varying,
    "Bln_Integrasi" character varying,
    "Tgl_Integrasi" character varying,
    "Usia_Integrasi" character varying,
    "Alamat_Provinsi" character varying,
    "Jenis_Pekerjaan" character varying,
    "Status_Tabungan" character varying,
    "Alamat_Kabupaten" character varying,
    "Alamat_Kecamatan" character varying,
    "Status_Aktivitas" character varying,
    "Jabatan_Pekerjaan" character varying,
    "Keahlian_Khusus_A" character varying,
    "Keahlian_Khusus_B" character varying,
    "Keahlian_Khusus_C" character varying,
    "Keahlian_Khusus_D" character varying,
    "Keahlian_Khusus_E" character varying,
    "Jenis_Pemberdayaan" character varying,
    "Status_Pemberdayaan" character varying,
    "Gaji_Rata_rata_Pekerjaan" character varying,
    "Aset_Hak_Milik_Mobil__Rp_" character varying,
    "Aset_Hak_Milik_Motor__Rp_" character varying,
    "Aset_Hak_Milik_Rumah__m2_" character varying,
    "Aset_Hak_Milik_Tanah__m2_" character varying
);


ALTER TABLE public.raw_b1 OWNER TO admin;

--
-- TOC entry 238 (class 1259 OID 172035)
-- Name: cleaned_user_area_b1; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.cleaned_user_area_b1 AS
 WITH latest_gen AS (
         SELECT max(raw_b1._airbyte_generation_id) AS last_gen
           FROM public.raw_b1
        )
 SELECT r."K",
    r."JK",
    r."LMG",
    r."Ver",
    r."Code",
    r."Tabungan",
    r."Status_Nikah",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Provinsi")::text) AS "Alamat_Provinsi",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Provinsi", ''::character varying))) AS normalized_provinsi,
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower(TRIM(BOTH FROM regexp_replace((COALESCE(r."Alamat_Kabupaten", ''::character varying))::text, '^(kabupaten|kab|kab\.)\s*'::text, ''::text))) AS normalized_kabupaten,
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Kecamatan", ''::character varying))) AS normalized_kecamatan,
    regexp_replace((COALESCE(r."Code", ''::character varying))::text, '[^0-9\.]'::text, ''::text) AS cleaned_fullcode,
    'B1'::text AS kantor_id
   FROM (public.raw_b1 r
     JOIN latest_gen lg ON ((r._airbyte_generation_id = lg.last_gen)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.cleaned_user_area_b1 OWNER TO admin;

--
-- TOC entry 223 (class 1259 OID 33172)
-- Name: raw_b2; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_b2 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "K" character varying,
    "JK" character varying,
    "SD" character varying,
    "LMG" character varying,
    "No_" numeric,
    "SMA" character varying,
    "SMP" character varying,
    "Ver" character varying,
    "Code" character varying,
    "Utang" character varying,
    "Jur_S1" character varying,
    "Jur_S2" character varying,
    "Jur_S3" character varying,
    "Mentor" character varying,
    "Piutang" character varying,
    "Univ_S1" character varying,
    "Univ_S2" character varying,
    "Univ_S3" character varying,
    "Tabungan" character varying,
    "Th_Lahir" character varying,
    "Bln_Lahir" character varying,
    "Jur_D1_D4" character varying,
    "Pesantren" character varying,
    "Tgl_Lahir" character varying,
    "Gelar_Awal" character varying,
    "Univ_D1_D4" character varying,
    "Usia_Lahir" character varying,
    "Gelar_Akhir" character varying,
    "Status_Nikah" character varying,
    "Th_Integrasi" character varying,
    "Alamat_Negara" character varying,
    "Bln_Integrasi" character varying,
    "Tgl_Integrasi" character varying,
    "Usia_Integrasi" character varying,
    "Alamat_Provinsi" character varying,
    "Jenis_Pekerjaan" character varying,
    "Status_Tabungan" character varying,
    "Alamat_Kabupaten" character varying,
    "Alamat_Kecamatan" character varying,
    "Status_Aktivitas" character varying,
    "Jabatan_Pekerjaan" character varying,
    "Keahlian_Khusus_A" character varying,
    "Keahlian_Khusus_B" character varying,
    "Keahlian_Khusus_C" character varying,
    "Keahlian_Khusus_D" character varying,
    "Keahlian_Khusus_E" character varying,
    "Jenis_Pemberdayaan" character varying,
    "Status_Pemberdayaan" character varying,
    "Gaji_Rata_rata_Pekerjaan" character varying,
    "Aset_Hak_Milik_Mobil__Rp_" character varying,
    "Aset_Hak_Milik_Motor__Rp_" character varying,
    "Aset_Hak_Milik_Rumah__m2_" character varying,
    "Aset_Hak_Milik_Tanah__m2_" character varying,
    "Instansi_Pekerjaan" character varying
);


ALTER TABLE public.raw_b2 OWNER TO admin;

--
-- TOC entry 239 (class 1259 OID 172040)
-- Name: cleaned_user_area_b2; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.cleaned_user_area_b2 AS
 WITH latest_gen AS (
         SELECT max(raw_b2._airbyte_generation_id) AS last_gen
           FROM public.raw_b2
        )
 SELECT r."K",
    r."JK",
    r."LMG",
    r."Ver",
    r."Code",
    r."Tabungan",
    r."Status_Nikah",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Provinsi")::text) AS "Alamat_Provinsi",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Provinsi", ''::character varying))) AS normalized_provinsi,
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower(TRIM(BOTH FROM regexp_replace((COALESCE(r."Alamat_Kabupaten", ''::character varying))::text, '^(kabupaten|kab|kab\.)\s*'::text, ''::text))) AS normalized_kabupaten,
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Kecamatan", ''::character varying))) AS normalized_kecamatan,
    regexp_replace((COALESCE(r."Code", ''::character varying))::text, '[^0-9\.]'::text, ''::text) AS cleaned_fullcode,
    'B2'::text AS kantor_id
   FROM (public.raw_b2 r
     JOIN latest_gen lg ON ((r._airbyte_generation_id = lg.last_gen)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.cleaned_user_area_b2 OWNER TO admin;

--
-- TOC entry 224 (class 1259 OID 33186)
-- Name: raw_b3; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_b3 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "K" character varying,
    "JK" character varying,
    "SD" character varying,
    "LMG" character varying,
    "No_" numeric,
    "SMA" character varying,
    "SMP" character varying,
    "Ver" character varying,
    "Code" character varying,
    "null" character varying,
    "Utang" character varying,
    "Jur_S1" character varying,
    "Jur_S2" character varying,
    "Jur_S3" character varying,
    "Mentor" character varying,
    "Piutang" character varying,
    "Univ_S1" character varying,
    "Univ_S2" character varying,
    "Univ_S3" character varying,
    "Tabungan" character varying,
    "Th_Lahir" character varying,
    "Bln_Lahir" character varying,
    "Jur_D1_D4" character varying,
    "Pesantren" character varying,
    "Tgl_Lahir" character varying,
    "Gelar_Awal" character varying,
    "Univ_D1_D4" character varying,
    "Usia_Lahir" character varying,
    "Gelar_Akhir" character varying,
    "Status_Nikah" character varying,
    "Th_Integrasi" character varying,
    "Alamat_Negara" character varying,
    "Bln_Integrasi" character varying,
    "Tgl_Integrasi" character varying,
    "Usia_Integrasi" character varying,
    "Alamat_Provinsi" character varying,
    "Jenis_Pekerjaan" character varying,
    "Status_Tabungan" character varying,
    "Alamat_Kabupaten" character varying,
    "Alamat_Kecamatan" character varying,
    "Status_Aktivitas" character varying,
    "Jabatan_Pekerjaan" character varying,
    "Keahlian_Khusus_A" character varying,
    "Keahlian_Khusus_B" character varying,
    "Keahlian_Khusus_C" character varying,
    "Keahlian_Khusus_D" character varying,
    "Keahlian_Khusus_E" character varying,
    "Jenis_Pemberdayaan" character varying,
    "Status_Pemberdayaan" character varying,
    "Gaji_Rata_rata_Pekerjaan" character varying,
    "Aset_Hak_Milik_Mobil__Rp_" character varying,
    "Aset_Hak_Milik_Motor__Rp_" character varying,
    "Aset_Hak_Milik_Rumah__m2_" character varying,
    "Aset_Hak_Milik_Tanah__m2_" character varying,
    "Instansi_Pekerjaan" character varying
);


ALTER TABLE public.raw_b3 OWNER TO admin;

--
-- TOC entry 240 (class 1259 OID 172045)
-- Name: cleaned_user_area_b3; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.cleaned_user_area_b3 AS
 WITH latest_gen AS (
         SELECT max(raw_b3._airbyte_generation_id) AS last_gen
           FROM public.raw_b3
        )
 SELECT r."K",
    r."JK",
    r."LMG",
    r."Ver",
    r."Code",
    r."Tabungan",
    r."Status_Nikah",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Provinsi")::text) AS "Alamat_Provinsi",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Provinsi", ''::character varying))) AS normalized_provinsi,
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower(TRIM(BOTH FROM regexp_replace((COALESCE(r."Alamat_Kabupaten", ''::character varying))::text, '^(kabupaten|kab|kab\.)\s*'::text, ''::text))) AS normalized_kabupaten,
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Kecamatan", ''::character varying))) AS normalized_kecamatan,
    regexp_replace((COALESCE(r."Code", ''::character varying))::text, '[^0-9\.]'::text, ''::text) AS cleaned_fullcode,
    'B3'::text AS kantor_id
   FROM (public.raw_b3 r
     JOIN latest_gen lg ON ((r._airbyte_generation_id = lg.last_gen)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.cleaned_user_area_b3 OWNER TO admin;

--
-- TOC entry 225 (class 1259 OID 33199)
-- Name: raw_b4; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_b4 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "K" character varying,
    "JK" character varying,
    "SD" character varying,
    "LMG" character varying,
    "No_" numeric,
    "SMA" character varying,
    "SMP" character varying,
    "Ver" character varying,
    "Code" character varying,
    "null" character varying,
    "Utang" character varying,
    "Jur_S1" character varying,
    "Jur_S2" character varying,
    "Jur_S3" character varying,
    "Mentor" character varying,
    "Piutang" character varying,
    "Univ_S1" character varying,
    "Univ_S2" character varying,
    "Univ_S3" character varying,
    "Tabungan" character varying,
    "Th_Lahir" character varying,
    "Bln_Lahir" character varying,
    "Jur_D1_D4" character varying,
    "Pesantren" character varying,
    "Tgl_Lahir" character varying,
    "Gelar_Awal" character varying,
    "Univ_D1_D4" character varying,
    "Usia_Lahir" character varying,
    "Gelar_Akhir" character varying,
    "Status_Nikah" character varying,
    "Th_Integrasi" character varying,
    "Alamat_Negara" character varying,
    "Bln_Integrasi" character varying,
    "Tgl_Integrasi" character varying,
    "Usia_Integrasi" character varying,
    "Alamat_Provinsi" character varying,
    "Jenis_Pekerjaan" character varying,
    "Status_Tabungan" character varying,
    "Alamat_Kabupaten" character varying,
    "Alamat_Kecamatan" character varying,
    "Status_Aktivitas" character varying,
    "Jabatan_Pekerjaan" character varying,
    "Keahlian_Khusus_A" character varying,
    "Keahlian_Khusus_B" character varying,
    "Keahlian_Khusus_C" character varying,
    "Keahlian_Khusus_D" character varying,
    "Keahlian_Khusus_E" character varying,
    "Jenis_Pemberdayaan" character varying,
    "Status_Pemberdayaan" character varying,
    "Gaji_Rata_rata_Pekerjaan" character varying,
    "Aset_Hak_Milik_Mobil__Rp_" character varying,
    "Aset_Hak_Milik_Motor__Rp_" character varying,
    "Aset_Hak_Milik_Rumah__m2_" character varying,
    "Aset_Hak_Milik_Tanah__m2_" character varying,
    "Instansi_Pekerjaan" character varying
);


ALTER TABLE public.raw_b4 OWNER TO admin;

--
-- TOC entry 241 (class 1259 OID 172050)
-- Name: cleaned_user_area_b4; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.cleaned_user_area_b4 AS
 WITH latest_gen AS (
         SELECT max(raw_b4._airbyte_generation_id) AS last_gen
           FROM public.raw_b4
        )
 SELECT r."K",
    r."JK",
    r."LMG",
    r."Ver",
    r."Code",
    r."Tabungan",
    r."Status_Nikah",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Provinsi")::text) AS "Alamat_Provinsi",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Provinsi", ''::character varying))) AS normalized_provinsi,
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower(TRIM(BOTH FROM regexp_replace((COALESCE(r."Alamat_Kabupaten", ''::character varying))::text, '^(kabupaten|kab|kab\.)\s*'::text, ''::text))) AS normalized_kabupaten,
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Kecamatan", ''::character varying))) AS normalized_kecamatan,
    regexp_replace((COALESCE(r."Code", ''::character varying))::text, '[^0-9\.]'::text, ''::text) AS cleaned_fullcode,
    'B4'::text AS kantor_id
   FROM (public.raw_b4 r
     JOIN latest_gen lg ON ((r._airbyte_generation_id = lg.last_gen)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.cleaned_user_area_b4 OWNER TO admin;

--
-- TOC entry 226 (class 1259 OID 33242)
-- Name: raw_b5; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_b5 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "K" character varying,
    "JK" character varying,
    "SD" character varying,
    "LMG" character varying,
    "No_" character varying,
    "SMA" character varying,
    "SMP" character varying,
    "Ver" character varying,
    "Code" character varying,
    "null" character varying,
    "Utang" character varying,
    "Jur_S1" character varying,
    "Jur_S2" character varying,
    "Jur_S3" character varying,
    "Mentor" character varying,
    "Piutang" character varying,
    "Univ_S1" character varying,
    "Univ_S2" character varying,
    "Univ_S3" character varying,
    "Tabungan" character varying,
    "Th_Lahir" character varying,
    "Bln_Lahir" character varying,
    "Jur_D1_D4" character varying,
    "Pesantren" character varying,
    "Tgl_Lahir" character varying,
    "Gelar_Awal" character varying,
    "Univ_D1_D4" character varying,
    "Usia_Lahir" character varying,
    "Gelar_Akhir" character varying,
    "Status_Nikah" character varying,
    "Th_Integrasi" character varying,
    "Alamat_Negara" character varying,
    "Bln_Integrasi" character varying,
    "Tgl_Integrasi" character varying,
    "Usia_Integrasi" character varying,
    "Alamat_Provinsi" character varying,
    "Jenis_Pekerjaan" character varying,
    "Status_Tabungan" character varying,
    "Alamat_Kabupaten" character varying,
    "Alamat_Kecamatan" character varying,
    "Status_Aktivitas" character varying,
    "Jabatan_Pekerjaan" character varying,
    "Keahlian_Khusus_A" character varying,
    "Keahlian_Khusus_B" character varying,
    "Keahlian_Khusus_C" character varying,
    "Keahlian_Khusus_D" character varying,
    "Keahlian_Khusus_E" character varying,
    "Jenis_Pemberdayaan" character varying,
    "Status_Pemberdayaan" character varying,
    "Gaji_Rata_rata_Pekerjaan" character varying,
    "Aset_Hak_Milik_Mobil__Rp_" character varying,
    "Aset_Hak_Milik_Motor__Rp_" character varying,
    "Aset_Hak_Milik_Rumah__m2_" character varying,
    "Aset_Hak_Milik_Tanah__m2_" character varying
);


ALTER TABLE public.raw_b5 OWNER TO admin;

--
-- TOC entry 242 (class 1259 OID 172055)
-- Name: cleaned_user_area_b5; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.cleaned_user_area_b5 AS
 WITH latest_gen AS (
         SELECT max(raw_b5._airbyte_generation_id) AS last_gen
           FROM public.raw_b5
        )
 SELECT r."K",
    r."JK",
    r."LMG",
    r."Ver",
    r."Code",
    r."Tabungan",
    r."Status_Nikah",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Provinsi")::text) AS "Alamat_Provinsi",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Provinsi", ''::character varying))) AS normalized_provinsi,
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower(TRIM(BOTH FROM regexp_replace((COALESCE(r."Alamat_Kabupaten", ''::character varying))::text, '^(kabupaten|kab|kab\.)\s*'::text, ''::text))) AS normalized_kabupaten,
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Kecamatan", ''::character varying))) AS normalized_kecamatan,
    regexp_replace((COALESCE(r."Code", ''::character varying))::text, '[^0-9\.]'::text, ''::text) AS cleaned_fullcode,
    'B5'::text AS kantor_id
   FROM (public.raw_b5 r
     JOIN latest_gen lg ON ((r._airbyte_generation_id = lg.last_gen)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.cleaned_user_area_b5 OWNER TO admin;

--
-- TOC entry 227 (class 1259 OID 33254)
-- Name: raw_c1; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_c1 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "K" character varying,
    "JK" character varying,
    "SD" character varying,
    "LMG" character varying,
    "No_" character varying,
    "SMA" character varying,
    "SMP" character varying,
    "Ver" character varying,
    "Code" character varying,
    "null" character varying,
    "Utang" character varying,
    "Jur_S1" character varying,
    "Jur_S2" character varying,
    "Jur_S3" character varying,
    "Mentor" character varying,
    "Piutang" character varying,
    "Univ_S1" character varying,
    "Univ_S2" character varying,
    "Univ_S3" character varying,
    "Tabungan" character varying,
    "Th_Lahir" character varying,
    "Bln_Lahir" character varying,
    "Jur_D1_D4" character varying,
    "Pesantren" character varying,
    "Tgl_Lahir" character varying,
    "Gelar_Awal" character varying,
    "Univ_D1_D4" character varying,
    "Usia_Lahir" character varying,
    "Gelar_Akhir" character varying,
    "Status_Nikah" character varying,
    "Th_Integrasi" character varying,
    "Alamat_Negara" character varying,
    "Bln_Integrasi" character varying,
    "Tgl_Integrasi" character varying,
    "Usia_Integrasi" character varying,
    "Alamat_Provinsi" character varying,
    "Jenis_Pekerjaan" character varying,
    "Status_Tabungan" character varying,
    "Alamat_Kabupaten" character varying,
    "Alamat_Kecamatan" character varying,
    "Status_Aktivitas" character varying,
    "Jabatan_Pekerjaan" character varying,
    "Keahlian_Khusus_A" character varying,
    "Keahlian_Khusus_B" character varying,
    "Keahlian_Khusus_C" character varying,
    "Keahlian_Khusus_D" character varying,
    "Keahlian_Khusus_E" character varying,
    "Jenis_Pemberdayaan" character varying,
    "Status_Pemberdayaan" character varying,
    "Gaji_Rata_rata_Pekerjaan" character varying,
    "Aset_Hak_Milik_Mobil__Rp_" character varying,
    "Aset_Hak_Milik_Motor__Rp_" character varying,
    "Aset_Hak_Milik_Rumah__m2_" character varying,
    "Aset_Hak_Milik_Tanah__m2_" character varying
);


ALTER TABLE public.raw_c1 OWNER TO admin;

--
-- TOC entry 243 (class 1259 OID 172060)
-- Name: cleaned_user_area_c1; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.cleaned_user_area_c1 AS
 WITH latest_gen AS (
         SELECT max(raw_c1._airbyte_generation_id) AS last_gen
           FROM public.raw_c1
        )
 SELECT r."K",
    r."JK",
    r."LMG",
    r."Ver",
    r."Code",
    r."Tabungan",
    r."Status_Nikah",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Provinsi")::text) AS "Alamat_Provinsi",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Provinsi", ''::character varying))) AS normalized_provinsi,
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower(TRIM(BOTH FROM regexp_replace((COALESCE(r."Alamat_Kabupaten", ''::character varying))::text, '^(kabupaten|kab|kab\.)\s*'::text, ''::text))) AS normalized_kabupaten,
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Kecamatan", ''::character varying))) AS normalized_kecamatan,
    regexp_replace((COALESCE(r."Code", ''::character varying))::text, '[^0-9\.]'::text, ''::text) AS cleaned_fullcode,
    'C1'::text AS kantor_id
   FROM (public.raw_c1 r
     JOIN latest_gen lg ON ((r._airbyte_generation_id = lg.last_gen)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.cleaned_user_area_c1 OWNER TO admin;

--
-- TOC entry 228 (class 1259 OID 33274)
-- Name: raw_c2; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_c2 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "K" character varying,
    "JK" character varying,
    "SD" character varying,
    "LMG" character varying,
    "No_" character varying,
    "SMA" character varying,
    "SMP" character varying,
    "Ver" character varying,
    "Code" character varying,
    "null" character varying,
    "Utang" character varying,
    "Jur_S1" character varying,
    "Jur_S2" character varying,
    "Jur_S3" character varying,
    "Mentor" character varying,
    "Piutang" character varying,
    "Univ_S1" character varying,
    "Univ_S2" character varying,
    "Univ_S3" character varying,
    "Tabungan" character varying,
    "Th_Lahir" character varying,
    "Bln_Lahir" character varying,
    "Jur_D1_D4" character varying,
    "Pesantren" character varying,
    "Tgl_Lahir" character varying,
    "Gelar_Awal" character varying,
    "Univ_D1_D4" character varying,
    "Usia_Lahir" character varying,
    "Gelar_Akhir" character varying,
    "Status_Nikah" character varying,
    "Th_Integrasi" character varying,
    "Alamat_Negara" character varying,
    "Bln_Integrasi" character varying,
    "Tgl_Integrasi" character varying,
    "Usia_Integrasi" character varying,
    "Alamat_Provinsi" character varying,
    "Jenis_Pekerjaan" character varying,
    "Status_Tabungan" character varying,
    "Alamat_Kabupaten" character varying,
    "Alamat_Kecamatan" character varying,
    "Status_Aktivitas" character varying,
    "Jabatan_Pekerjaan" character varying,
    "Keahlian_Khusus_A" character varying,
    "Keahlian_Khusus_B" character varying,
    "Keahlian_Khusus_C" character varying,
    "Keahlian_Khusus_D" character varying,
    "Keahlian_Khusus_E" character varying,
    "Jenis_Pemberdayaan" character varying,
    "Status_Pemberdayaan" character varying,
    "Gaji_Rata_rata_Pekerjaan" character varying,
    "Aset_Hak_Milik_Mobil__Rp_" character varying,
    "Aset_Hak_Milik_Motor__Rp_" character varying,
    "Aset_Hak_Milik_Rumah__m2_" character varying,
    "Aset_Hak_Milik_Tanah__m2_" character varying,
    "Nama_Lengkap" character varying,
    "Instansi_Pekerjaan" character varying
);


ALTER TABLE public.raw_c2 OWNER TO admin;

--
-- TOC entry 244 (class 1259 OID 172065)
-- Name: cleaned_user_area_c2; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.cleaned_user_area_c2 AS
 WITH latest_gen AS (
         SELECT max(raw_c2._airbyte_generation_id) AS last_gen
           FROM public.raw_c2
        )
 SELECT r."K",
    r."JK",
    r."LMG",
    r."Ver",
    r."Code",
    r."Tabungan",
    r."Status_Nikah",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Provinsi")::text) AS "Alamat_Provinsi",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Provinsi", ''::character varying))) AS normalized_provinsi,
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower(TRIM(BOTH FROM regexp_replace((COALESCE(r."Alamat_Kabupaten", ''::character varying))::text, '^(kabupaten|kab|kab\.)\s*'::text, ''::text))) AS normalized_kabupaten,
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Kecamatan", ''::character varying))) AS normalized_kecamatan,
    regexp_replace((COALESCE(r."Code", ''::character varying))::text, '[^0-9\.]'::text, ''::text) AS cleaned_fullcode,
    'C2'::text AS kantor_id
   FROM (public.raw_c2 r
     JOIN latest_gen lg ON ((r._airbyte_generation_id = lg.last_gen)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.cleaned_user_area_c2 OWNER TO admin;

--
-- TOC entry 229 (class 1259 OID 33287)
-- Name: raw_c3; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_c3 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "K" character varying,
    "JK" character varying,
    "SD" character varying,
    "LMG" character varying,
    "No_" character varying,
    "SMA" character varying,
    "SMP" character varying,
    "Ver" character varying,
    "Code" character varying,
    "null" character varying,
    "Utang" character varying,
    "Jur_S1" character varying,
    "Jur_S2" character varying,
    "Jur_S3" character varying,
    "Mentor" character varying,
    "Piutang" character varying,
    "Univ_S1" character varying,
    "Univ_S2" character varying,
    "Univ_S3" character varying,
    "Tabungan" character varying,
    "Th_Lahir" character varying,
    "Bln_Lahir" character varying,
    "Jur_D1_D4" character varying,
    "Pesantren" character varying,
    "Tgl_Lahir" character varying,
    "Gelar_Awal" character varying,
    "Univ_D1_D4" character varying,
    "Usia_Lahir" character varying,
    "Gelar_Akhir" character varying,
    "Status_Nikah" character varying,
    "Th_Integrasi" character varying,
    "Alamat_Negara" character varying,
    "Bln_Integrasi" character varying,
    "Tgl_Integrasi" character varying,
    "Usia_Integrasi" character varying,
    "Alamat_Provinsi" character varying,
    "Jenis_Pekerjaan" character varying,
    "Status_Tabungan" character varying,
    "Alamat_Kabupaten" character varying,
    "Alamat_Kecamatan" character varying,
    "Status_Aktivitas" character varying,
    "Jabatan_Pekerjaan" character varying,
    "Keahlian_Khusus_A" character varying,
    "Keahlian_Khusus_B" character varying,
    "Keahlian_Khusus_C" character varying,
    "Keahlian_Khusus_D" character varying,
    "Keahlian_Khusus_E" character varying,
    "Jenis_Pemberdayaan" character varying,
    "Status_Pemberdayaan" character varying,
    "Gaji_Rata_rata_Pekerjaan" character varying,
    "Aset_Hak_Milik_Mobil__Rp_" character varying,
    "Aset_Hak_Milik_Motor__Rp_" character varying,
    "Aset_Hak_Milik_Rumah__m2_" character varying,
    "Aset_Hak_Milik_Tanah__m2_" character varying
);


ALTER TABLE public.raw_c3 OWNER TO admin;

--
-- TOC entry 245 (class 1259 OID 172070)
-- Name: cleaned_user_area_c3; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.cleaned_user_area_c3 AS
 WITH latest_gen AS (
         SELECT max(raw_c3._airbyte_generation_id) AS last_gen
           FROM public.raw_c3
        )
 SELECT r."K",
    r."JK",
    r."LMG",
    r."Ver",
    r."Code",
    r."Tabungan",
    r."Status_Nikah",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Provinsi")::text) AS "Alamat_Provinsi",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Provinsi", ''::character varying))) AS normalized_provinsi,
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower(TRIM(BOTH FROM regexp_replace((COALESCE(r."Alamat_Kabupaten", ''::character varying))::text, '^(kabupaten|kab|kab\.)\s*'::text, ''::text))) AS normalized_kabupaten,
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Kecamatan", ''::character varying))) AS normalized_kecamatan,
    regexp_replace((COALESCE(r."Code", ''::character varying))::text, '[^0-9\.]'::text, ''::text) AS cleaned_fullcode,
    'C3'::text AS kantor_id
   FROM (public.raw_c3 r
     JOIN latest_gen lg ON ((r._airbyte_generation_id = lg.last_gen)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.cleaned_user_area_c3 OWNER TO admin;

--
-- TOC entry 230 (class 1259 OID 33300)
-- Name: raw_c4; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_c4 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "K" character varying,
    "JK" character varying,
    "SD" character varying,
    "LMG" character varying,
    "No_" character varying,
    "SMA" character varying,
    "SMP" character varying,
    "Ver" character varying,
    "Code" character varying,
    "Utang" character varying,
    "Jur_S1" character varying,
    "Jur_S2" character varying,
    "Jur_S3" character varying,
    "Mentor" character varying,
    "Piutang" character varying,
    "Univ_S1" character varying,
    "Univ_S2" character varying,
    "Univ_S3" character varying,
    "Tabungan" character varying,
    "Th_Lahir" character varying,
    "Bln_Lahir" character varying,
    "Jur_D1_D4" character varying,
    "Pesantren" character varying,
    "Tgl_Lahir" character varying,
    "Gelar_Awal" character varying,
    "Univ_D1_D4" character varying,
    "Usia_Lahir" character varying,
    "Gelar_Akhir" character varying,
    "Status_Nikah" character varying,
    "Th_Integrasi" character varying,
    "Alamat_Negara" character varying,
    "Bln_Integrasi" character varying,
    "Tgl_Integrasi" character varying,
    "Usia_Integrasi" character varying,
    "Alamat_Provinsi" character varying,
    "Jenis_Pekerjaan" character varying,
    "Status_Tabungan" character varying,
    "Alamat_Kabupaten" character varying,
    "Alamat_Kecamatan" character varying,
    "Status_Aktivitas" character varying,
    "Jabatan_Pekerjaan" character varying,
    "Keahlian_Khusus_A" character varying,
    "Keahlian_Khusus_B" character varying,
    "Keahlian_Khusus_C" character varying,
    "Keahlian_Khusus_D" character varying,
    "Keahlian_Khusus_E" character varying,
    "Jenis_Pemberdayaan" character varying,
    "Status_Pemberdayaan" character varying,
    "Gaji_Rata_rata_Pekerjaan" character varying,
    "Aset_Hak_Milik_Mobil__Rp_" character varying,
    "Aset_Hak_Milik_Motor__Rp_" character varying,
    "Aset_Hak_Milik_Rumah__m2_" character varying,
    "Aset_Hak_Milik_Tanah__m2_" character varying
);


ALTER TABLE public.raw_c4 OWNER TO admin;

--
-- TOC entry 246 (class 1259 OID 172075)
-- Name: cleaned_user_area_c4; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.cleaned_user_area_c4 AS
 WITH latest_gen AS (
         SELECT max(raw_c4._airbyte_generation_id) AS last_gen
           FROM public.raw_c4
        )
 SELECT r."K",
    r."JK",
    r."LMG",
    r."Ver",
    r."Code",
    r."Tabungan",
    r."Status_Nikah",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Provinsi")::text) AS "Alamat_Provinsi",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Provinsi", ''::character varying))) AS normalized_provinsi,
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower(TRIM(BOTH FROM regexp_replace((COALESCE(r."Alamat_Kabupaten", ''::character varying))::text, '^(kabupaten|kab|kab\.)\s*'::text, ''::text))) AS normalized_kabupaten,
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    lower(TRIM(BOTH FROM COALESCE(r."Alamat_Kecamatan", ''::character varying))) AS normalized_kecamatan,
    regexp_replace((COALESCE(r."Code", ''::character varying))::text, '[^0-9\.]'::text, ''::text) AS cleaned_fullcode,
    'C4'::text AS kantor_id
   FROM (public.raw_c4 r
     JOIN latest_gen lg ON ((r._airbyte_generation_id = lg.last_gen)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.cleaned_user_area_c4 OWNER TO admin;

--
-- TOC entry 233 (class 1259 OID 168947)
-- Name: master_reference_area; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.master_reference_area (
    kode_provinsi character varying(10),
    provinsi character varying(255),
    kode_kabupaten character varying(10),
    kabupaten_kota character varying(255),
    kode_kecamatan character varying(10),
    kecamatan character varying(255),
    fullcode character varying(30),
    normalized_provinsi character varying(255),
    normalized_kabupaten character varying(255),
    normalized_kecamatan character varying(255)
);


ALTER TABLE public.master_reference_area OWNER TO admin;

--
-- TOC entry 235 (class 1259 OID 168965)
-- Name: resolved_user_area_a1; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.resolved_user_area_a1 AS
 SELECT c."K",
    c."JK",
    c."LMG",
    c."Ver",
    c."Code",
    c."Tabungan",
    c."Status_Nikah",
    c."Status_Tabungan",
    c."Status_Aktivitas",
    c."Alamat_Negara",
    c."Alamat_Provinsi",
    c.normalized_provinsi,
    c.normalized_kabupaten,
    c."Alamat_Kecamatan",
    c.normalized_kecamatan,
    c.cleaned_fullcode,
    c.kantor_id,
    COALESCE(m_code.provinsi, m_name.provinsi) AS final_provinsi,
    COALESCE(m_code.kabupaten_kota, m_name.kabupaten_kota) AS final_kabupaten,
    COALESCE(m_code.kecamatan, m_name.kecamatan) AS final_kecamatan,
    COALESCE(m_code.kode_provinsi, m_name.kode_provinsi) AS final_kode_provinsi,
    COALESCE(m_code.kode_kabupaten, m_name.kode_kabupaten) AS final_kode_kabupaten,
    COALESCE(m_code.kode_kecamatan, m_name.kode_kecamatan) AS final_kode_kecamatan,
    COALESCE(m_code.fullcode, m_name.fullcode) AS final_fullcode,
        CASE
            WHEN (((c.cleaned_fullcode IS NULL) OR (c.cleaned_fullcode = ''::text)) AND ((c.normalized_kecamatan = ''::text) AND (c.normalized_kabupaten = ''::text) AND (c.normalized_provinsi = ''::text))) THEN 'EMPTY_DATA'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND ((m_code.normalized_provinsi)::text = c.normalized_provinsi) AND ((m_code.normalized_kabupaten)::text = c.normalized_kabupaten) AND ((m_code.normalized_kecamatan)::text = c.normalized_kecamatan)) THEN 'VALID'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND (((m_code.normalized_provinsi)::text <> c.normalized_provinsi) OR ((m_code.normalized_kabupaten)::text <> c.normalized_kabupaten) OR ((m_code.normalized_kecamatan)::text <> c.normalized_kecamatan))) THEN 'CONFLICT_NAME'::text
            WHEN ((m_code.fullcode IS NULL) AND (m_name.fullcode IS NOT NULL)) THEN 'MATCH_BY_NAME'::text
            WHEN ((c.cleaned_fullcode IS NOT NULL) AND (c.cleaned_fullcode <> ''::text) AND (m_code.fullcode IS NULL)) THEN 'INVALID_CODE'::text
            ELSE 'UNKNOWN'::text
        END AS validation_status
   FROM ((analytics.cleaned_user_area_a1 c
     LEFT JOIN public.master_reference_area m_code ON ((c.cleaned_fullcode = (m_code.fullcode)::text)))
     LEFT JOIN public.master_reference_area m_name ON (((c.normalized_provinsi = (m_name.normalized_provinsi)::text) AND (c.normalized_kabupaten = (m_name.normalized_kabupaten)::text) AND (c.normalized_kecamatan = (m_name.normalized_kecamatan)::text))));


ALTER VIEW analytics.resolved_user_area_a1 OWNER TO admin;

--
-- TOC entry 247 (class 1259 OID 172080)
-- Name: resolved_user_area_a2; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.resolved_user_area_a2 AS
 SELECT c."K",
    c."JK",
    c."LMG",
    c."Ver",
    c."Code",
    c."Tabungan",
    c."Status_Nikah",
    c."Status_Tabungan",
    c."Status_Aktivitas",
    c."Alamat_Negara",
    c."Alamat_Provinsi",
    c.normalized_provinsi,
    c.normalized_kabupaten,
    c."Alamat_Kecamatan",
    c.normalized_kecamatan,
    c.cleaned_fullcode,
    c.kantor_id,
    COALESCE(m_code.provinsi, m_name.provinsi) AS final_provinsi,
    COALESCE(m_code.kabupaten_kota, m_name.kabupaten_kota) AS final_kabupaten,
    COALESCE(m_code.kecamatan, m_name.kecamatan) AS final_kecamatan,
    COALESCE(m_code.kode_provinsi, m_name.kode_provinsi) AS final_kode_provinsi,
    COALESCE(m_code.kode_kabupaten, m_name.kode_kabupaten) AS final_kode_kabupaten,
    COALESCE(m_code.kode_kecamatan, m_name.kode_kecamatan) AS final_kode_kecamatan,
    COALESCE(m_code.fullcode, m_name.fullcode) AS final_fullcode,
        CASE
            WHEN (((c.cleaned_fullcode IS NULL) OR (c.cleaned_fullcode = ''::text)) AND (c.normalized_kecamatan = ''::text) AND (c.normalized_kabupaten = ''::text) AND (c.normalized_provinsi = ''::text)) THEN 'EMPTY_DATA'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND ((m_code.normalized_provinsi)::text = c.normalized_provinsi) AND ((m_code.normalized_kabupaten)::text = c.normalized_kabupaten) AND ((m_code.normalized_kecamatan)::text = c.normalized_kecamatan)) THEN 'VALID'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND (((m_code.normalized_provinsi)::text <> c.normalized_provinsi) OR ((m_code.normalized_kabupaten)::text <> c.normalized_kabupaten) OR ((m_code.normalized_kecamatan)::text <> c.normalized_kecamatan))) THEN 'CONFLICT_NAME'::text
            WHEN ((m_code.fullcode IS NULL) AND (m_name.fullcode IS NOT NULL)) THEN 'MATCH_BY_NAME'::text
            WHEN ((c.cleaned_fullcode IS NOT NULL) AND (c.cleaned_fullcode <> ''::text) AND (m_code.fullcode IS NULL)) THEN 'INVALID_CODE'::text
            ELSE 'UNKNOWN'::text
        END AS validation_status
   FROM ((analytics.cleaned_user_area_a2 c
     LEFT JOIN public.master_reference_area m_code ON ((c.cleaned_fullcode = (m_code.fullcode)::text)))
     LEFT JOIN public.master_reference_area m_name ON (((c.normalized_provinsi = (m_name.normalized_provinsi)::text) AND (c.normalized_kabupaten = (m_name.normalized_kabupaten)::text) AND (c.normalized_kecamatan = (m_name.normalized_kecamatan)::text))));


ALTER VIEW analytics.resolved_user_area_a2 OWNER TO admin;

--
-- TOC entry 248 (class 1259 OID 172085)
-- Name: resolved_user_area_a3; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.resolved_user_area_a3 AS
 SELECT c."K",
    c."JK",
    c."LMG",
    c."Ver",
    c."Code",
    c."Tabungan",
    c."Status_Nikah",
    c."Status_Tabungan",
    c."Status_Aktivitas",
    c."Alamat_Negara",
    c."Alamat_Provinsi",
    c.normalized_provinsi,
    c.normalized_kabupaten,
    c."Alamat_Kecamatan",
    c.normalized_kecamatan,
    c.cleaned_fullcode,
    c.kantor_id,
    COALESCE(m_code.provinsi, m_name.provinsi) AS final_provinsi,
    COALESCE(m_code.kabupaten_kota, m_name.kabupaten_kota) AS final_kabupaten,
    COALESCE(m_code.kecamatan, m_name.kecamatan) AS final_kecamatan,
    COALESCE(m_code.kode_provinsi, m_name.kode_provinsi) AS final_kode_provinsi,
    COALESCE(m_code.kode_kabupaten, m_name.kode_kabupaten) AS final_kode_kabupaten,
    COALESCE(m_code.kode_kecamatan, m_name.kode_kecamatan) AS final_kode_kecamatan,
    COALESCE(m_code.fullcode, m_name.fullcode) AS final_fullcode,
        CASE
            WHEN (((c.cleaned_fullcode IS NULL) OR (c.cleaned_fullcode = ''::text)) AND (c.normalized_kecamatan = ''::text) AND (c.normalized_kabupaten = ''::text) AND (c.normalized_provinsi = ''::text)) THEN 'EMPTY_DATA'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND ((m_code.normalized_provinsi)::text = c.normalized_provinsi) AND ((m_code.normalized_kabupaten)::text = c.normalized_kabupaten) AND ((m_code.normalized_kecamatan)::text = c.normalized_kecamatan)) THEN 'VALID'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND (((m_code.normalized_provinsi)::text <> c.normalized_provinsi) OR ((m_code.normalized_kabupaten)::text <> c.normalized_kabupaten) OR ((m_code.normalized_kecamatan)::text <> c.normalized_kecamatan))) THEN 'CONFLICT_NAME'::text
            WHEN ((m_code.fullcode IS NULL) AND (m_name.fullcode IS NOT NULL)) THEN 'MATCH_BY_NAME'::text
            WHEN ((c.cleaned_fullcode IS NOT NULL) AND (c.cleaned_fullcode <> ''::text) AND (m_code.fullcode IS NULL)) THEN 'INVALID_CODE'::text
            ELSE 'UNKNOWN'::text
        END AS validation_status
   FROM ((analytics.cleaned_user_area_a3 c
     LEFT JOIN public.master_reference_area m_code ON ((c.cleaned_fullcode = (m_code.fullcode)::text)))
     LEFT JOIN public.master_reference_area m_name ON (((c.normalized_provinsi = (m_name.normalized_provinsi)::text) AND (c.normalized_kabupaten = (m_name.normalized_kabupaten)::text) AND (c.normalized_kecamatan = (m_name.normalized_kecamatan)::text))));


ALTER VIEW analytics.resolved_user_area_a3 OWNER TO admin;

--
-- TOC entry 249 (class 1259 OID 172090)
-- Name: resolved_user_area_b1; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.resolved_user_area_b1 AS
 SELECT c."K",
    c."JK",
    c."LMG",
    c."Ver",
    c."Code",
    c."Tabungan",
    c."Status_Nikah",
    c."Status_Tabungan",
    c."Status_Aktivitas",
    c."Alamat_Negara",
    c."Alamat_Provinsi",
    c.normalized_provinsi,
    c.normalized_kabupaten,
    c."Alamat_Kecamatan",
    c.normalized_kecamatan,
    c.cleaned_fullcode,
    c.kantor_id,
    COALESCE(m_code.provinsi, m_name.provinsi) AS final_provinsi,
    COALESCE(m_code.kabupaten_kota, m_name.kabupaten_kota) AS final_kabupaten,
    COALESCE(m_code.kecamatan, m_name.kecamatan) AS final_kecamatan,
    COALESCE(m_code.kode_provinsi, m_name.kode_provinsi) AS final_kode_provinsi,
    COALESCE(m_code.kode_kabupaten, m_name.kode_kabupaten) AS final_kode_kabupaten,
    COALESCE(m_code.kode_kecamatan, m_name.kode_kecamatan) AS final_kode_kecamatan,
    COALESCE(m_code.fullcode, m_name.fullcode) AS final_fullcode,
        CASE
            WHEN (((c.cleaned_fullcode IS NULL) OR (c.cleaned_fullcode = ''::text)) AND (c.normalized_kecamatan = ''::text) AND (c.normalized_kabupaten = ''::text) AND (c.normalized_provinsi = ''::text)) THEN 'EMPTY_DATA'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND ((m_code.normalized_provinsi)::text = c.normalized_provinsi) AND ((m_code.normalized_kabupaten)::text = c.normalized_kabupaten) AND ((m_code.normalized_kecamatan)::text = c.normalized_kecamatan)) THEN 'VALID'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND (((m_code.normalized_provinsi)::text <> c.normalized_provinsi) OR ((m_code.normalized_kabupaten)::text <> c.normalized_kabupaten) OR ((m_code.normalized_kecamatan)::text <> c.normalized_kecamatan))) THEN 'CONFLICT_NAME'::text
            WHEN ((m_code.fullcode IS NULL) AND (m_name.fullcode IS NOT NULL)) THEN 'MATCH_BY_NAME'::text
            WHEN ((c.cleaned_fullcode IS NOT NULL) AND (c.cleaned_fullcode <> ''::text) AND (m_code.fullcode IS NULL)) THEN 'INVALID_CODE'::text
            ELSE 'UNKNOWN'::text
        END AS validation_status
   FROM ((analytics.cleaned_user_area_b1 c
     LEFT JOIN public.master_reference_area m_code ON ((c.cleaned_fullcode = (m_code.fullcode)::text)))
     LEFT JOIN public.master_reference_area m_name ON (((c.normalized_provinsi = (m_name.normalized_provinsi)::text) AND (c.normalized_kabupaten = (m_name.normalized_kabupaten)::text) AND (c.normalized_kecamatan = (m_name.normalized_kecamatan)::text))));


ALTER VIEW analytics.resolved_user_area_b1 OWNER TO admin;

--
-- TOC entry 250 (class 1259 OID 172095)
-- Name: resolved_user_area_b2; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.resolved_user_area_b2 AS
 SELECT c."K",
    c."JK",
    c."LMG",
    c."Ver",
    c."Code",
    c."Tabungan",
    c."Status_Nikah",
    c."Status_Tabungan",
    c."Status_Aktivitas",
    c."Alamat_Negara",
    c."Alamat_Provinsi",
    c.normalized_provinsi,
    c.normalized_kabupaten,
    c."Alamat_Kecamatan",
    c.normalized_kecamatan,
    c.cleaned_fullcode,
    c.kantor_id,
    COALESCE(m_code.provinsi, m_name.provinsi) AS final_provinsi,
    COALESCE(m_code.kabupaten_kota, m_name.kabupaten_kota) AS final_kabupaten,
    COALESCE(m_code.kecamatan, m_name.kecamatan) AS final_kecamatan,
    COALESCE(m_code.kode_provinsi, m_name.kode_provinsi) AS final_kode_provinsi,
    COALESCE(m_code.kode_kabupaten, m_name.kode_kabupaten) AS final_kode_kabupaten,
    COALESCE(m_code.kode_kecamatan, m_name.kode_kecamatan) AS final_kode_kecamatan,
    COALESCE(m_code.fullcode, m_name.fullcode) AS final_fullcode,
        CASE
            WHEN (((c.cleaned_fullcode IS NULL) OR (c.cleaned_fullcode = ''::text)) AND (c.normalized_kecamatan = ''::text) AND (c.normalized_kabupaten = ''::text) AND (c.normalized_provinsi = ''::text)) THEN 'EMPTY_DATA'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND ((m_code.normalized_provinsi)::text = c.normalized_provinsi) AND ((m_code.normalized_kabupaten)::text = c.normalized_kabupaten) AND ((m_code.normalized_kecamatan)::text = c.normalized_kecamatan)) THEN 'VALID'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND (((m_code.normalized_provinsi)::text <> c.normalized_provinsi) OR ((m_code.normalized_kabupaten)::text <> c.normalized_kabupaten) OR ((m_code.normalized_kecamatan)::text <> c.normalized_kecamatan))) THEN 'CONFLICT_NAME'::text
            WHEN ((m_code.fullcode IS NULL) AND (m_name.fullcode IS NOT NULL)) THEN 'MATCH_BY_NAME'::text
            WHEN ((c.cleaned_fullcode IS NOT NULL) AND (c.cleaned_fullcode <> ''::text) AND (m_code.fullcode IS NULL)) THEN 'INVALID_CODE'::text
            ELSE 'UNKNOWN'::text
        END AS validation_status
   FROM ((analytics.cleaned_user_area_b2 c
     LEFT JOIN public.master_reference_area m_code ON ((c.cleaned_fullcode = (m_code.fullcode)::text)))
     LEFT JOIN public.master_reference_area m_name ON (((c.normalized_provinsi = (m_name.normalized_provinsi)::text) AND (c.normalized_kabupaten = (m_name.normalized_kabupaten)::text) AND (c.normalized_kecamatan = (m_name.normalized_kecamatan)::text))));


ALTER VIEW analytics.resolved_user_area_b2 OWNER TO admin;

--
-- TOC entry 251 (class 1259 OID 172100)
-- Name: resolved_user_area_b3; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.resolved_user_area_b3 AS
 SELECT c."K",
    c."JK",
    c."LMG",
    c."Ver",
    c."Code",
    c."Tabungan",
    c."Status_Nikah",
    c."Status_Tabungan",
    c."Status_Aktivitas",
    c."Alamat_Negara",
    c."Alamat_Provinsi",
    c.normalized_provinsi,
    c.normalized_kabupaten,
    c."Alamat_Kecamatan",
    c.normalized_kecamatan,
    c.cleaned_fullcode,
    c.kantor_id,
    COALESCE(m_code.provinsi, m_name.provinsi) AS final_provinsi,
    COALESCE(m_code.kabupaten_kota, m_name.kabupaten_kota) AS final_kabupaten,
    COALESCE(m_code.kecamatan, m_name.kecamatan) AS final_kecamatan,
    COALESCE(m_code.kode_provinsi, m_name.kode_provinsi) AS final_kode_provinsi,
    COALESCE(m_code.kode_kabupaten, m_name.kode_kabupaten) AS final_kode_kabupaten,
    COALESCE(m_code.kode_kecamatan, m_name.kode_kecamatan) AS final_kode_kecamatan,
    COALESCE(m_code.fullcode, m_name.fullcode) AS final_fullcode,
        CASE
            WHEN (((c.cleaned_fullcode IS NULL) OR (c.cleaned_fullcode = ''::text)) AND (c.normalized_kecamatan = ''::text) AND (c.normalized_kabupaten = ''::text) AND (c.normalized_provinsi = ''::text)) THEN 'EMPTY_DATA'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND ((m_code.normalized_provinsi)::text = c.normalized_provinsi) AND ((m_code.normalized_kabupaten)::text = c.normalized_kabupaten) AND ((m_code.normalized_kecamatan)::text = c.normalized_kecamatan)) THEN 'VALID'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND (((m_code.normalized_provinsi)::text <> c.normalized_provinsi) OR ((m_code.normalized_kabupaten)::text <> c.normalized_kabupaten) OR ((m_code.normalized_kecamatan)::text <> c.normalized_kecamatan))) THEN 'CONFLICT_NAME'::text
            WHEN ((m_code.fullcode IS NULL) AND (m_name.fullcode IS NOT NULL)) THEN 'MATCH_BY_NAME'::text
            WHEN ((c.cleaned_fullcode IS NOT NULL) AND (c.cleaned_fullcode <> ''::text) AND (m_code.fullcode IS NULL)) THEN 'INVALID_CODE'::text
            ELSE 'UNKNOWN'::text
        END AS validation_status
   FROM ((analytics.cleaned_user_area_b3 c
     LEFT JOIN public.master_reference_area m_code ON ((c.cleaned_fullcode = (m_code.fullcode)::text)))
     LEFT JOIN public.master_reference_area m_name ON (((c.normalized_provinsi = (m_name.normalized_provinsi)::text) AND (c.normalized_kabupaten = (m_name.normalized_kabupaten)::text) AND (c.normalized_kecamatan = (m_name.normalized_kecamatan)::text))));


ALTER VIEW analytics.resolved_user_area_b3 OWNER TO admin;

--
-- TOC entry 252 (class 1259 OID 172105)
-- Name: resolved_user_area_b4; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.resolved_user_area_b4 AS
 SELECT c."K",
    c."JK",
    c."LMG",
    c."Ver",
    c."Code",
    c."Tabungan",
    c."Status_Nikah",
    c."Status_Tabungan",
    c."Status_Aktivitas",
    c."Alamat_Negara",
    c."Alamat_Provinsi",
    c.normalized_provinsi,
    c.normalized_kabupaten,
    c."Alamat_Kecamatan",
    c.normalized_kecamatan,
    c.cleaned_fullcode,
    c.kantor_id,
    COALESCE(m_code.provinsi, m_name.provinsi) AS final_provinsi,
    COALESCE(m_code.kabupaten_kota, m_name.kabupaten_kota) AS final_kabupaten,
    COALESCE(m_code.kecamatan, m_name.kecamatan) AS final_kecamatan,
    COALESCE(m_code.kode_provinsi, m_name.kode_provinsi) AS final_kode_provinsi,
    COALESCE(m_code.kode_kabupaten, m_name.kode_kabupaten) AS final_kode_kabupaten,
    COALESCE(m_code.kode_kecamatan, m_name.kode_kecamatan) AS final_kode_kecamatan,
    COALESCE(m_code.fullcode, m_name.fullcode) AS final_fullcode,
        CASE
            WHEN (((c.cleaned_fullcode IS NULL) OR (c.cleaned_fullcode = ''::text)) AND (c.normalized_kecamatan = ''::text) AND (c.normalized_kabupaten = ''::text) AND (c.normalized_provinsi = ''::text)) THEN 'EMPTY_DATA'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND ((m_code.normalized_provinsi)::text = c.normalized_provinsi) AND ((m_code.normalized_kabupaten)::text = c.normalized_kabupaten) AND ((m_code.normalized_kecamatan)::text = c.normalized_kecamatan)) THEN 'VALID'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND (((m_code.normalized_provinsi)::text <> c.normalized_provinsi) OR ((m_code.normalized_kabupaten)::text <> c.normalized_kabupaten) OR ((m_code.normalized_kecamatan)::text <> c.normalized_kecamatan))) THEN 'CONFLICT_NAME'::text
            WHEN ((m_code.fullcode IS NULL) AND (m_name.fullcode IS NOT NULL)) THEN 'MATCH_BY_NAME'::text
            WHEN ((c.cleaned_fullcode IS NOT NULL) AND (c.cleaned_fullcode <> ''::text) AND (m_code.fullcode IS NULL)) THEN 'INVALID_CODE'::text
            ELSE 'UNKNOWN'::text
        END AS validation_status
   FROM ((analytics.cleaned_user_area_b4 c
     LEFT JOIN public.master_reference_area m_code ON ((c.cleaned_fullcode = (m_code.fullcode)::text)))
     LEFT JOIN public.master_reference_area m_name ON (((c.normalized_provinsi = (m_name.normalized_provinsi)::text) AND (c.normalized_kabupaten = (m_name.normalized_kabupaten)::text) AND (c.normalized_kecamatan = (m_name.normalized_kecamatan)::text))));


ALTER VIEW analytics.resolved_user_area_b4 OWNER TO admin;

--
-- TOC entry 253 (class 1259 OID 172110)
-- Name: resolved_user_area_b5; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.resolved_user_area_b5 AS
 SELECT c."K",
    c."JK",
    c."LMG",
    c."Ver",
    c."Code",
    c."Tabungan",
    c."Status_Nikah",
    c."Status_Tabungan",
    c."Status_Aktivitas",
    c."Alamat_Negara",
    c."Alamat_Provinsi",
    c.normalized_provinsi,
    c.normalized_kabupaten,
    c."Alamat_Kecamatan",
    c.normalized_kecamatan,
    c.cleaned_fullcode,
    c.kantor_id,
    COALESCE(m_code.provinsi, m_name.provinsi) AS final_provinsi,
    COALESCE(m_code.kabupaten_kota, m_name.kabupaten_kota) AS final_kabupaten,
    COALESCE(m_code.kecamatan, m_name.kecamatan) AS final_kecamatan,
    COALESCE(m_code.kode_provinsi, m_name.kode_provinsi) AS final_kode_provinsi,
    COALESCE(m_code.kode_kabupaten, m_name.kode_kabupaten) AS final_kode_kabupaten,
    COALESCE(m_code.kode_kecamatan, m_name.kode_kecamatan) AS final_kode_kecamatan,
    COALESCE(m_code.fullcode, m_name.fullcode) AS final_fullcode,
        CASE
            WHEN (((c.cleaned_fullcode IS NULL) OR (c.cleaned_fullcode = ''::text)) AND (c.normalized_kecamatan = ''::text) AND (c.normalized_kabupaten = ''::text) AND (c.normalized_provinsi = ''::text)) THEN 'EMPTY_DATA'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND ((m_code.normalized_provinsi)::text = c.normalized_provinsi) AND ((m_code.normalized_kabupaten)::text = c.normalized_kabupaten) AND ((m_code.normalized_kecamatan)::text = c.normalized_kecamatan)) THEN 'VALID'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND (((m_code.normalized_provinsi)::text <> c.normalized_provinsi) OR ((m_code.normalized_kabupaten)::text <> c.normalized_kabupaten) OR ((m_code.normalized_kecamatan)::text <> c.normalized_kecamatan))) THEN 'CONFLICT_NAME'::text
            WHEN ((m_code.fullcode IS NULL) AND (m_name.fullcode IS NOT NULL)) THEN 'MATCH_BY_NAME'::text
            WHEN ((c.cleaned_fullcode IS NOT NULL) AND (c.cleaned_fullcode <> ''::text) AND (m_code.fullcode IS NULL)) THEN 'INVALID_CODE'::text
            ELSE 'UNKNOWN'::text
        END AS validation_status
   FROM ((analytics.cleaned_user_area_b5 c
     LEFT JOIN public.master_reference_area m_code ON ((c.cleaned_fullcode = (m_code.fullcode)::text)))
     LEFT JOIN public.master_reference_area m_name ON (((c.normalized_provinsi = (m_name.normalized_provinsi)::text) AND (c.normalized_kabupaten = (m_name.normalized_kabupaten)::text) AND (c.normalized_kecamatan = (m_name.normalized_kecamatan)::text))));


ALTER VIEW analytics.resolved_user_area_b5 OWNER TO admin;

--
-- TOC entry 254 (class 1259 OID 172115)
-- Name: resolved_user_area_c1; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.resolved_user_area_c1 AS
 SELECT c."K",
    c."JK",
    c."LMG",
    c."Ver",
    c."Code",
    c."Tabungan",
    c."Status_Nikah",
    c."Status_Tabungan",
    c."Status_Aktivitas",
    c."Alamat_Negara",
    c."Alamat_Provinsi",
    c.normalized_provinsi,
    c.normalized_kabupaten,
    c."Alamat_Kecamatan",
    c.normalized_kecamatan,
    c.cleaned_fullcode,
    c.kantor_id,
    COALESCE(m_code.provinsi, m_name.provinsi) AS final_provinsi,
    COALESCE(m_code.kabupaten_kota, m_name.kabupaten_kota) AS final_kabupaten,
    COALESCE(m_code.kecamatan, m_name.kecamatan) AS final_kecamatan,
    COALESCE(m_code.kode_provinsi, m_name.kode_provinsi) AS final_kode_provinsi,
    COALESCE(m_code.kode_kabupaten, m_name.kode_kabupaten) AS final_kode_kabupaten,
    COALESCE(m_code.kode_kecamatan, m_name.kode_kecamatan) AS final_kode_kecamatan,
    COALESCE(m_code.fullcode, m_name.fullcode) AS final_fullcode,
        CASE
            WHEN (((c.cleaned_fullcode IS NULL) OR (c.cleaned_fullcode = ''::text)) AND (c.normalized_kecamatan = ''::text) AND (c.normalized_kabupaten = ''::text) AND (c.normalized_provinsi = ''::text)) THEN 'EMPTY_DATA'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND ((m_code.normalized_provinsi)::text = c.normalized_provinsi) AND ((m_code.normalized_kabupaten)::text = c.normalized_kabupaten) AND ((m_code.normalized_kecamatan)::text = c.normalized_kecamatan)) THEN 'VALID'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND (((m_code.normalized_provinsi)::text <> c.normalized_provinsi) OR ((m_code.normalized_kabupaten)::text <> c.normalized_kabupaten) OR ((m_code.normalized_kecamatan)::text <> c.normalized_kecamatan))) THEN 'CONFLICT_NAME'::text
            WHEN ((m_code.fullcode IS NULL) AND (m_name.fullcode IS NOT NULL)) THEN 'MATCH_BY_NAME'::text
            WHEN ((c.cleaned_fullcode IS NOT NULL) AND (c.cleaned_fullcode <> ''::text) AND (m_code.fullcode IS NULL)) THEN 'INVALID_CODE'::text
            ELSE 'UNKNOWN'::text
        END AS validation_status
   FROM ((analytics.cleaned_user_area_c1 c
     LEFT JOIN public.master_reference_area m_code ON ((c.cleaned_fullcode = (m_code.fullcode)::text)))
     LEFT JOIN public.master_reference_area m_name ON (((c.normalized_provinsi = (m_name.normalized_provinsi)::text) AND (c.normalized_kabupaten = (m_name.normalized_kabupaten)::text) AND (c.normalized_kecamatan = (m_name.normalized_kecamatan)::text))));


ALTER VIEW analytics.resolved_user_area_c1 OWNER TO admin;

--
-- TOC entry 255 (class 1259 OID 172120)
-- Name: resolved_user_area_c2; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.resolved_user_area_c2 AS
 SELECT c."K",
    c."JK",
    c."LMG",
    c."Ver",
    c."Code",
    c."Tabungan",
    c."Status_Nikah",
    c."Status_Tabungan",
    c."Status_Aktivitas",
    c."Alamat_Negara",
    c."Alamat_Provinsi",
    c.normalized_provinsi,
    c.normalized_kabupaten,
    c."Alamat_Kecamatan",
    c.normalized_kecamatan,
    c.cleaned_fullcode,
    c.kantor_id,
    COALESCE(m_code.provinsi, m_name.provinsi) AS final_provinsi,
    COALESCE(m_code.kabupaten_kota, m_name.kabupaten_kota) AS final_kabupaten,
    COALESCE(m_code.kecamatan, m_name.kecamatan) AS final_kecamatan,
    COALESCE(m_code.kode_provinsi, m_name.kode_provinsi) AS final_kode_provinsi,
    COALESCE(m_code.kode_kabupaten, m_name.kode_kabupaten) AS final_kode_kabupaten,
    COALESCE(m_code.kode_kecamatan, m_name.kode_kecamatan) AS final_kode_kecamatan,
    COALESCE(m_code.fullcode, m_name.fullcode) AS final_fullcode,
        CASE
            WHEN (((c.cleaned_fullcode IS NULL) OR (c.cleaned_fullcode = ''::text)) AND (c.normalized_kecamatan = ''::text) AND (c.normalized_kabupaten = ''::text) AND (c.normalized_provinsi = ''::text)) THEN 'EMPTY_DATA'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND ((m_code.normalized_provinsi)::text = c.normalized_provinsi) AND ((m_code.normalized_kabupaten)::text = c.normalized_kabupaten) AND ((m_code.normalized_kecamatan)::text = c.normalized_kecamatan)) THEN 'VALID'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND (((m_code.normalized_provinsi)::text <> c.normalized_provinsi) OR ((m_code.normalized_kabupaten)::text <> c.normalized_kabupaten) OR ((m_code.normalized_kecamatan)::text <> c.normalized_kecamatan))) THEN 'CONFLICT_NAME'::text
            WHEN ((m_code.fullcode IS NULL) AND (m_name.fullcode IS NOT NULL)) THEN 'MATCH_BY_NAME'::text
            WHEN ((c.cleaned_fullcode IS NOT NULL) AND (c.cleaned_fullcode <> ''::text) AND (m_code.fullcode IS NULL)) THEN 'INVALID_CODE'::text
            ELSE 'UNKNOWN'::text
        END AS validation_status
   FROM ((analytics.cleaned_user_area_c2 c
     LEFT JOIN public.master_reference_area m_code ON ((c.cleaned_fullcode = (m_code.fullcode)::text)))
     LEFT JOIN public.master_reference_area m_name ON (((c.normalized_provinsi = (m_name.normalized_provinsi)::text) AND (c.normalized_kabupaten = (m_name.normalized_kabupaten)::text) AND (c.normalized_kecamatan = (m_name.normalized_kecamatan)::text))));


ALTER VIEW analytics.resolved_user_area_c2 OWNER TO admin;

--
-- TOC entry 256 (class 1259 OID 172125)
-- Name: resolved_user_area_c3; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.resolved_user_area_c3 AS
 SELECT c."K",
    c."JK",
    c."LMG",
    c."Ver",
    c."Code",
    c."Tabungan",
    c."Status_Nikah",
    c."Status_Tabungan",
    c."Status_Aktivitas",
    c."Alamat_Negara",
    c."Alamat_Provinsi",
    c.normalized_provinsi,
    c.normalized_kabupaten,
    c."Alamat_Kecamatan",
    c.normalized_kecamatan,
    c.cleaned_fullcode,
    c.kantor_id,
    COALESCE(m_code.provinsi, m_name.provinsi) AS final_provinsi,
    COALESCE(m_code.kabupaten_kota, m_name.kabupaten_kota) AS final_kabupaten,
    COALESCE(m_code.kecamatan, m_name.kecamatan) AS final_kecamatan,
    COALESCE(m_code.kode_provinsi, m_name.kode_provinsi) AS final_kode_provinsi,
    COALESCE(m_code.kode_kabupaten, m_name.kode_kabupaten) AS final_kode_kabupaten,
    COALESCE(m_code.kode_kecamatan, m_name.kode_kecamatan) AS final_kode_kecamatan,
    COALESCE(m_code.fullcode, m_name.fullcode) AS final_fullcode,
        CASE
            WHEN (((c.cleaned_fullcode IS NULL) OR (c.cleaned_fullcode = ''::text)) AND (c.normalized_kecamatan = ''::text) AND (c.normalized_kabupaten = ''::text) AND (c.normalized_provinsi = ''::text)) THEN 'EMPTY_DATA'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND ((m_code.normalized_provinsi)::text = c.normalized_provinsi) AND ((m_code.normalized_kabupaten)::text = c.normalized_kabupaten) AND ((m_code.normalized_kecamatan)::text = c.normalized_kecamatan)) THEN 'VALID'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND (((m_code.normalized_provinsi)::text <> c.normalized_provinsi) OR ((m_code.normalized_kabupaten)::text <> c.normalized_kabupaten) OR ((m_code.normalized_kecamatan)::text <> c.normalized_kecamatan))) THEN 'CONFLICT_NAME'::text
            WHEN ((m_code.fullcode IS NULL) AND (m_name.fullcode IS NOT NULL)) THEN 'MATCH_BY_NAME'::text
            WHEN ((c.cleaned_fullcode IS NOT NULL) AND (c.cleaned_fullcode <> ''::text) AND (m_code.fullcode IS NULL)) THEN 'INVALID_CODE'::text
            ELSE 'UNKNOWN'::text
        END AS validation_status
   FROM ((analytics.cleaned_user_area_c3 c
     LEFT JOIN public.master_reference_area m_code ON ((c.cleaned_fullcode = (m_code.fullcode)::text)))
     LEFT JOIN public.master_reference_area m_name ON (((c.normalized_provinsi = (m_name.normalized_provinsi)::text) AND (c.normalized_kabupaten = (m_name.normalized_kabupaten)::text) AND (c.normalized_kecamatan = (m_name.normalized_kecamatan)::text))));


ALTER VIEW analytics.resolved_user_area_c3 OWNER TO admin;

--
-- TOC entry 257 (class 1259 OID 172130)
-- Name: resolved_user_area_c4; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.resolved_user_area_c4 AS
 SELECT c."K",
    c."JK",
    c."LMG",
    c."Ver",
    c."Code",
    c."Tabungan",
    c."Status_Nikah",
    c."Status_Tabungan",
    c."Status_Aktivitas",
    c."Alamat_Negara",
    c."Alamat_Provinsi",
    c.normalized_provinsi,
    c.normalized_kabupaten,
    c."Alamat_Kecamatan",
    c.normalized_kecamatan,
    c.cleaned_fullcode,
    c.kantor_id,
    COALESCE(m_code.provinsi, m_name.provinsi) AS final_provinsi,
    COALESCE(m_code.kabupaten_kota, m_name.kabupaten_kota) AS final_kabupaten,
    COALESCE(m_code.kecamatan, m_name.kecamatan) AS final_kecamatan,
    COALESCE(m_code.kode_provinsi, m_name.kode_provinsi) AS final_kode_provinsi,
    COALESCE(m_code.kode_kabupaten, m_name.kode_kabupaten) AS final_kode_kabupaten,
    COALESCE(m_code.kode_kecamatan, m_name.kode_kecamatan) AS final_kode_kecamatan,
    COALESCE(m_code.fullcode, m_name.fullcode) AS final_fullcode,
        CASE
            WHEN (((c.cleaned_fullcode IS NULL) OR (c.cleaned_fullcode = ''::text)) AND (c.normalized_kecamatan = ''::text) AND (c.normalized_kabupaten = ''::text) AND (c.normalized_provinsi = ''::text)) THEN 'EMPTY_DATA'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND ((m_code.normalized_provinsi)::text = c.normalized_provinsi) AND ((m_code.normalized_kabupaten)::text = c.normalized_kabupaten) AND ((m_code.normalized_kecamatan)::text = c.normalized_kecamatan)) THEN 'VALID'::text
            WHEN ((m_code.fullcode IS NOT NULL) AND (((m_code.normalized_provinsi)::text <> c.normalized_provinsi) OR ((m_code.normalized_kabupaten)::text <> c.normalized_kabupaten) OR ((m_code.normalized_kecamatan)::text <> c.normalized_kecamatan))) THEN 'CONFLICT_NAME'::text
            WHEN ((m_code.fullcode IS NULL) AND (m_name.fullcode IS NOT NULL)) THEN 'MATCH_BY_NAME'::text
            WHEN ((c.cleaned_fullcode IS NOT NULL) AND (c.cleaned_fullcode <> ''::text) AND (m_code.fullcode IS NULL)) THEN 'INVALID_CODE'::text
            ELSE 'UNKNOWN'::text
        END AS validation_status
   FROM ((analytics.cleaned_user_area_c4 c
     LEFT JOIN public.master_reference_area m_code ON ((c.cleaned_fullcode = (m_code.fullcode)::text)))
     LEFT JOIN public.master_reference_area m_name ON (((c.normalized_provinsi = (m_name.normalized_provinsi)::text) AND (c.normalized_kabupaten = (m_name.normalized_kabupaten)::text) AND (c.normalized_kecamatan = (m_name.normalized_kecamatan)::text))));


ALTER VIEW analytics.resolved_user_area_c4 OWNER TO admin;

--
-- TOC entry 258 (class 1259 OID 195490)
-- Name: all_resolved_user_area; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.all_resolved_user_area AS
 SELECT 'A1'::text AS kantor,
    resolved_user_area_a1."K",
    resolved_user_area_a1."JK",
    resolved_user_area_a1."LMG",
    resolved_user_area_a1."Ver",
    resolved_user_area_a1."Code",
    resolved_user_area_a1."Tabungan",
    resolved_user_area_a1."Status_Nikah",
    resolved_user_area_a1."Status_Tabungan",
    resolved_user_area_a1."Status_Aktivitas",
    resolved_user_area_a1."Alamat_Negara",
    resolved_user_area_a1."Alamat_Provinsi",
    resolved_user_area_a1.normalized_provinsi,
    resolved_user_area_a1.normalized_kabupaten,
    resolved_user_area_a1."Alamat_Kecamatan",
    resolved_user_area_a1.normalized_kecamatan,
    resolved_user_area_a1.cleaned_fullcode,
    resolved_user_area_a1.kantor_id,
    resolved_user_area_a1.final_provinsi,
    resolved_user_area_a1.final_kabupaten,
    resolved_user_area_a1.final_kecamatan,
    resolved_user_area_a1.final_kode_provinsi,
    resolved_user_area_a1.final_kode_kabupaten,
    resolved_user_area_a1.final_kode_kecamatan,
    resolved_user_area_a1.final_fullcode,
    resolved_user_area_a1.validation_status
   FROM analytics.resolved_user_area_a1
UNION ALL
 SELECT 'A2'::text AS kantor,
    resolved_user_area_a2."K",
    resolved_user_area_a2."JK",
    resolved_user_area_a2."LMG",
    resolved_user_area_a2."Ver",
    resolved_user_area_a2."Code",
    resolved_user_area_a2."Tabungan",
    resolved_user_area_a2."Status_Nikah",
    resolved_user_area_a2."Status_Tabungan",
    resolved_user_area_a2."Status_Aktivitas",
    resolved_user_area_a2."Alamat_Negara",
    resolved_user_area_a2."Alamat_Provinsi",
    resolved_user_area_a2.normalized_provinsi,
    resolved_user_area_a2.normalized_kabupaten,
    resolved_user_area_a2."Alamat_Kecamatan",
    resolved_user_area_a2.normalized_kecamatan,
    resolved_user_area_a2.cleaned_fullcode,
    resolved_user_area_a2.kantor_id,
    resolved_user_area_a2.final_provinsi,
    resolved_user_area_a2.final_kabupaten,
    resolved_user_area_a2.final_kecamatan,
    resolved_user_area_a2.final_kode_provinsi,
    resolved_user_area_a2.final_kode_kabupaten,
    resolved_user_area_a2.final_kode_kecamatan,
    resolved_user_area_a2.final_fullcode,
    resolved_user_area_a2.validation_status
   FROM analytics.resolved_user_area_a2
UNION ALL
 SELECT 'A3'::text AS kantor,
    resolved_user_area_a3."K",
    resolved_user_area_a3."JK",
    resolved_user_area_a3."LMG",
    resolved_user_area_a3."Ver",
    resolved_user_area_a3."Code",
    resolved_user_area_a3."Tabungan",
    resolved_user_area_a3."Status_Nikah",
    resolved_user_area_a3."Status_Tabungan",
    resolved_user_area_a3."Status_Aktivitas",
    resolved_user_area_a3."Alamat_Negara",
    resolved_user_area_a3."Alamat_Provinsi",
    resolved_user_area_a3.normalized_provinsi,
    resolved_user_area_a3.normalized_kabupaten,
    resolved_user_area_a3."Alamat_Kecamatan",
    resolved_user_area_a3.normalized_kecamatan,
    resolved_user_area_a3.cleaned_fullcode,
    resolved_user_area_a3.kantor_id,
    resolved_user_area_a3.final_provinsi,
    resolved_user_area_a3.final_kabupaten,
    resolved_user_area_a3.final_kecamatan,
    resolved_user_area_a3.final_kode_provinsi,
    resolved_user_area_a3.final_kode_kabupaten,
    resolved_user_area_a3.final_kode_kecamatan,
    resolved_user_area_a3.final_fullcode,
    resolved_user_area_a3.validation_status
   FROM analytics.resolved_user_area_a3
UNION ALL
 SELECT 'B1'::text AS kantor,
    resolved_user_area_b1."K",
    resolved_user_area_b1."JK",
    resolved_user_area_b1."LMG",
    resolved_user_area_b1."Ver",
    resolved_user_area_b1."Code",
    resolved_user_area_b1."Tabungan",
    resolved_user_area_b1."Status_Nikah",
    resolved_user_area_b1."Status_Tabungan",
    resolved_user_area_b1."Status_Aktivitas",
    resolved_user_area_b1."Alamat_Negara",
    resolved_user_area_b1."Alamat_Provinsi",
    resolved_user_area_b1.normalized_provinsi,
    resolved_user_area_b1.normalized_kabupaten,
    resolved_user_area_b1."Alamat_Kecamatan",
    resolved_user_area_b1.normalized_kecamatan,
    resolved_user_area_b1.cleaned_fullcode,
    resolved_user_area_b1.kantor_id,
    resolved_user_area_b1.final_provinsi,
    resolved_user_area_b1.final_kabupaten,
    resolved_user_area_b1.final_kecamatan,
    resolved_user_area_b1.final_kode_provinsi,
    resolved_user_area_b1.final_kode_kabupaten,
    resolved_user_area_b1.final_kode_kecamatan,
    resolved_user_area_b1.final_fullcode,
    resolved_user_area_b1.validation_status
   FROM analytics.resolved_user_area_b1
UNION ALL
 SELECT 'B2'::text AS kantor,
    resolved_user_area_b2."K",
    resolved_user_area_b2."JK",
    resolved_user_area_b2."LMG",
    resolved_user_area_b2."Ver",
    resolved_user_area_b2."Code",
    resolved_user_area_b2."Tabungan",
    resolved_user_area_b2."Status_Nikah",
    resolved_user_area_b2."Status_Tabungan",
    resolved_user_area_b2."Status_Aktivitas",
    resolved_user_area_b2."Alamat_Negara",
    resolved_user_area_b2."Alamat_Provinsi",
    resolved_user_area_b2.normalized_provinsi,
    resolved_user_area_b2.normalized_kabupaten,
    resolved_user_area_b2."Alamat_Kecamatan",
    resolved_user_area_b2.normalized_kecamatan,
    resolved_user_area_b2.cleaned_fullcode,
    resolved_user_area_b2.kantor_id,
    resolved_user_area_b2.final_provinsi,
    resolved_user_area_b2.final_kabupaten,
    resolved_user_area_b2.final_kecamatan,
    resolved_user_area_b2.final_kode_provinsi,
    resolved_user_area_b2.final_kode_kabupaten,
    resolved_user_area_b2.final_kode_kecamatan,
    resolved_user_area_b2.final_fullcode,
    resolved_user_area_b2.validation_status
   FROM analytics.resolved_user_area_b2
UNION ALL
 SELECT 'B3'::text AS kantor,
    resolved_user_area_b3."K",
    resolved_user_area_b3."JK",
    resolved_user_area_b3."LMG",
    resolved_user_area_b3."Ver",
    resolved_user_area_b3."Code",
    resolved_user_area_b3."Tabungan",
    resolved_user_area_b3."Status_Nikah",
    resolved_user_area_b3."Status_Tabungan",
    resolved_user_area_b3."Status_Aktivitas",
    resolved_user_area_b3."Alamat_Negara",
    resolved_user_area_b3."Alamat_Provinsi",
    resolved_user_area_b3.normalized_provinsi,
    resolved_user_area_b3.normalized_kabupaten,
    resolved_user_area_b3."Alamat_Kecamatan",
    resolved_user_area_b3.normalized_kecamatan,
    resolved_user_area_b3.cleaned_fullcode,
    resolved_user_area_b3.kantor_id,
    resolved_user_area_b3.final_provinsi,
    resolved_user_area_b3.final_kabupaten,
    resolved_user_area_b3.final_kecamatan,
    resolved_user_area_b3.final_kode_provinsi,
    resolved_user_area_b3.final_kode_kabupaten,
    resolved_user_area_b3.final_kode_kecamatan,
    resolved_user_area_b3.final_fullcode,
    resolved_user_area_b3.validation_status
   FROM analytics.resolved_user_area_b3
UNION ALL
 SELECT 'B4'::text AS kantor,
    resolved_user_area_b4."K",
    resolved_user_area_b4."JK",
    resolved_user_area_b4."LMG",
    resolved_user_area_b4."Ver",
    resolved_user_area_b4."Code",
    resolved_user_area_b4."Tabungan",
    resolved_user_area_b4."Status_Nikah",
    resolved_user_area_b4."Status_Tabungan",
    resolved_user_area_b4."Status_Aktivitas",
    resolved_user_area_b4."Alamat_Negara",
    resolved_user_area_b4."Alamat_Provinsi",
    resolved_user_area_b4.normalized_provinsi,
    resolved_user_area_b4.normalized_kabupaten,
    resolved_user_area_b4."Alamat_Kecamatan",
    resolved_user_area_b4.normalized_kecamatan,
    resolved_user_area_b4.cleaned_fullcode,
    resolved_user_area_b4.kantor_id,
    resolved_user_area_b4.final_provinsi,
    resolved_user_area_b4.final_kabupaten,
    resolved_user_area_b4.final_kecamatan,
    resolved_user_area_b4.final_kode_provinsi,
    resolved_user_area_b4.final_kode_kabupaten,
    resolved_user_area_b4.final_kode_kecamatan,
    resolved_user_area_b4.final_fullcode,
    resolved_user_area_b4.validation_status
   FROM analytics.resolved_user_area_b4
UNION ALL
 SELECT 'B5'::text AS kantor,
    resolved_user_area_b5."K",
    resolved_user_area_b5."JK",
    resolved_user_area_b5."LMG",
    resolved_user_area_b5."Ver",
    resolved_user_area_b5."Code",
    resolved_user_area_b5."Tabungan",
    resolved_user_area_b5."Status_Nikah",
    resolved_user_area_b5."Status_Tabungan",
    resolved_user_area_b5."Status_Aktivitas",
    resolved_user_area_b5."Alamat_Negara",
    resolved_user_area_b5."Alamat_Provinsi",
    resolved_user_area_b5.normalized_provinsi,
    resolved_user_area_b5.normalized_kabupaten,
    resolved_user_area_b5."Alamat_Kecamatan",
    resolved_user_area_b5.normalized_kecamatan,
    resolved_user_area_b5.cleaned_fullcode,
    resolved_user_area_b5.kantor_id,
    resolved_user_area_b5.final_provinsi,
    resolved_user_area_b5.final_kabupaten,
    resolved_user_area_b5.final_kecamatan,
    resolved_user_area_b5.final_kode_provinsi,
    resolved_user_area_b5.final_kode_kabupaten,
    resolved_user_area_b5.final_kode_kecamatan,
    resolved_user_area_b5.final_fullcode,
    resolved_user_area_b5.validation_status
   FROM analytics.resolved_user_area_b5
UNION ALL
 SELECT 'C1'::text AS kantor,
    resolved_user_area_c1."K",
    resolved_user_area_c1."JK",
    resolved_user_area_c1."LMG",
    resolved_user_area_c1."Ver",
    resolved_user_area_c1."Code",
    resolved_user_area_c1."Tabungan",
    resolved_user_area_c1."Status_Nikah",
    resolved_user_area_c1."Status_Tabungan",
    resolved_user_area_c1."Status_Aktivitas",
    resolved_user_area_c1."Alamat_Negara",
    resolved_user_area_c1."Alamat_Provinsi",
    resolved_user_area_c1.normalized_provinsi,
    resolved_user_area_c1.normalized_kabupaten,
    resolved_user_area_c1."Alamat_Kecamatan",
    resolved_user_area_c1.normalized_kecamatan,
    resolved_user_area_c1.cleaned_fullcode,
    resolved_user_area_c1.kantor_id,
    resolved_user_area_c1.final_provinsi,
    resolved_user_area_c1.final_kabupaten,
    resolved_user_area_c1.final_kecamatan,
    resolved_user_area_c1.final_kode_provinsi,
    resolved_user_area_c1.final_kode_kabupaten,
    resolved_user_area_c1.final_kode_kecamatan,
    resolved_user_area_c1.final_fullcode,
    resolved_user_area_c1.validation_status
   FROM analytics.resolved_user_area_c1
UNION ALL
 SELECT 'C2'::text AS kantor,
    resolved_user_area_c2."K",
    resolved_user_area_c2."JK",
    resolved_user_area_c2."LMG",
    resolved_user_area_c2."Ver",
    resolved_user_area_c2."Code",
    resolved_user_area_c2."Tabungan",
    resolved_user_area_c2."Status_Nikah",
    resolved_user_area_c2."Status_Tabungan",
    resolved_user_area_c2."Status_Aktivitas",
    resolved_user_area_c2."Alamat_Negara",
    resolved_user_area_c2."Alamat_Provinsi",
    resolved_user_area_c2.normalized_provinsi,
    resolved_user_area_c2.normalized_kabupaten,
    resolved_user_area_c2."Alamat_Kecamatan",
    resolved_user_area_c2.normalized_kecamatan,
    resolved_user_area_c2.cleaned_fullcode,
    resolved_user_area_c2.kantor_id,
    resolved_user_area_c2.final_provinsi,
    resolved_user_area_c2.final_kabupaten,
    resolved_user_area_c2.final_kecamatan,
    resolved_user_area_c2.final_kode_provinsi,
    resolved_user_area_c2.final_kode_kabupaten,
    resolved_user_area_c2.final_kode_kecamatan,
    resolved_user_area_c2.final_fullcode,
    resolved_user_area_c2.validation_status
   FROM analytics.resolved_user_area_c2
UNION ALL
 SELECT 'C3'::text AS kantor,
    resolved_user_area_c3."K",
    resolved_user_area_c3."JK",
    resolved_user_area_c3."LMG",
    resolved_user_area_c3."Ver",
    resolved_user_area_c3."Code",
    resolved_user_area_c3."Tabungan",
    resolved_user_area_c3."Status_Nikah",
    resolved_user_area_c3."Status_Tabungan",
    resolved_user_area_c3."Status_Aktivitas",
    resolved_user_area_c3."Alamat_Negara",
    resolved_user_area_c3."Alamat_Provinsi",
    resolved_user_area_c3.normalized_provinsi,
    resolved_user_area_c3.normalized_kabupaten,
    resolved_user_area_c3."Alamat_Kecamatan",
    resolved_user_area_c3.normalized_kecamatan,
    resolved_user_area_c3.cleaned_fullcode,
    resolved_user_area_c3.kantor_id,
    resolved_user_area_c3.final_provinsi,
    resolved_user_area_c3.final_kabupaten,
    resolved_user_area_c3.final_kecamatan,
    resolved_user_area_c3.final_kode_provinsi,
    resolved_user_area_c3.final_kode_kabupaten,
    resolved_user_area_c3.final_kode_kecamatan,
    resolved_user_area_c3.final_fullcode,
    resolved_user_area_c3.validation_status
   FROM analytics.resolved_user_area_c3
UNION ALL
 SELECT 'C4'::text AS kantor,
    resolved_user_area_c4."K",
    resolved_user_area_c4."JK",
    resolved_user_area_c4."LMG",
    resolved_user_area_c4."Ver",
    resolved_user_area_c4."Code",
    resolved_user_area_c4."Tabungan",
    resolved_user_area_c4."Status_Nikah",
    resolved_user_area_c4."Status_Tabungan",
    resolved_user_area_c4."Status_Aktivitas",
    resolved_user_area_c4."Alamat_Negara",
    resolved_user_area_c4."Alamat_Provinsi",
    resolved_user_area_c4.normalized_provinsi,
    resolved_user_area_c4.normalized_kabupaten,
    resolved_user_area_c4."Alamat_Kecamatan",
    resolved_user_area_c4.normalized_kecamatan,
    resolved_user_area_c4.cleaned_fullcode,
    resolved_user_area_c4.kantor_id,
    resolved_user_area_c4.final_provinsi,
    resolved_user_area_c4.final_kabupaten,
    resolved_user_area_c4.final_kecamatan,
    resolved_user_area_c4.final_kode_provinsi,
    resolved_user_area_c4.final_kode_kabupaten,
    resolved_user_area_c4.final_kode_kecamatan,
    resolved_user_area_c4.final_fullcode,
    resolved_user_area_c4.validation_status
   FROM analytics.resolved_user_area_c4;


ALTER VIEW analytics.all_resolved_user_area OWNER TO admin;

--
-- TOC entry 294 (class 1259 OID 321138)
-- Name: raw_a1; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_a1 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "K" character varying,
    "JK" character varying,
    "SD" character varying,
    "LMG" character varying,
    "No_" character varying,
    "SMA" character varying,
    "SMP" character varying,
    "Ver" character varying,
    "Code" character varying,
    "Utang" character varying,
    "Jur_S1" character varying,
    "Jur_S2" character varying,
    "Jur_S3" character varying,
    "Mentor" character varying,
    "Piutang" character varying,
    "Univ_S1" character varying,
    "Univ_S2" character varying,
    "Univ_S3" character varying,
    "Tabungan" character varying,
    "Th_Lahir" character varying,
    "Bln_Lahir" character varying,
    "Jur_D1_D4" character varying,
    "Pesantren" character varying,
    "Tgl_Lahir" character varying,
    "Gelar_Awal" character varying,
    "Univ_D1_D4" character varying,
    "Usia_Lahir" character varying,
    "Gelar_Akhir" character varying,
    "Status_Nikah" character varying,
    "Th_Integrasi" character varying,
    "Alamat_Negara" character varying,
    "Bln_Integrasi" character varying,
    "Tgl_Integrasi" character varying,
    "Usia_Integrasi" character varying,
    "Alamat_Provinsi" character varying,
    "Jenis_Pekerjaan" character varying,
    "Status_Tabungan" character varying,
    "Alamat_Kabupaten" character varying,
    "Alamat_Kecamatan" character varying,
    "Status_Aktivitas" character varying,
    "Jabatan_Pekerjaan" character varying,
    "Keahlian_Khusus_A" character varying,
    "Keahlian_Khusus_B" character varying,
    "Keahlian_Khusus_C" character varying,
    "Keahlian_Khusus_D" character varying,
    "Keahlian_Khusus_E" character varying,
    "Jenis_Pemberdayaan" character varying,
    "Status_Pemberdayaan" character varying,
    "Gaji_Rata_rata_Pekerjaan" character varying,
    "Aset_Hak_Milik_Mobil__Rp_" character varying,
    "Aset_Hak_Milik_Motor__Rp_" character varying,
    "Aset_Hak_Milik_Rumah__m2_" character varying,
    "Aset_Hak_Milik_Tanah__m2_" character varying
);


ALTER TABLE public.raw_a1 OWNER TO admin;

--
-- TOC entry 296 (class 1259 OID 329225)
-- Name: stg_a1_capil; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_a1_capil AS
 WITH latest_pull AS (
         SELECT max(raw_a1._airbyte_generation_id) AS last_generation_id
           FROM public.raw_a1
        )
 SELECT r."K",
    r."JK",
    r."SD",
    r."LMG",
    r."SMA",
    r."SMP",
    r."Ver",
    r."Code",
    r."Utang",
    r."Jur_S1",
    r."Jur_S2",
    r."Jur_S3",
    r."Mentor",
    r."Piutang",
    r."Univ_S1",
    r."Univ_S2",
    r."Univ_S3",
    r."Tabungan",
    r."Th_Lahir",
    r."Bln_Lahir",
    r."Jur_D1_D4",
    r."Pesantren",
    r."Tgl_Lahir",
    r."Gelar_Awal",
    r."Univ_D1_D4",
    r."Usia_Lahir",
    r."Gelar_Akhir",
    r."Status_Nikah",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Tgl_Integrasi",
    r."Usia_Integrasi",
    r."Alamat_Provinsi",
    r."Jenis_Pekerjaan",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    r."Jabatan_Pekerjaan",
    r."Keahlian_Khusus_A",
    r."Keahlian_Khusus_B",
    r."Keahlian_Khusus_C",
    r."Keahlian_Khusus_D",
    r."Keahlian_Khusus_E",
    r."Jenis_Pemberdayaan",
    r."Status_Pemberdayaan",
    r."Gaji_Rata_rata_Pekerjaan",
    r."Aset_Hak_Milik_Mobil__Rp_",
    r."Aset_Hak_Milik_Motor__Rp_",
    r."Aset_Hak_Milik_Rumah__m2_",
    r."Aset_Hak_Milik_Tanah__m2_",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    'A1'::text AS kantor_id
   FROM (public.raw_a1 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.stg_a1_capil OWNER TO admin;

--
-- TOC entry 295 (class 1259 OID 329222)
-- Name: stg_a2_capil; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_a2_capil AS
 WITH latest_pull AS (
         SELECT max(raw_a2._airbyte_generation_id) AS last_generation_id
           FROM public.raw_a2
        )
 SELECT r."K",
    r."JK",
    r."SD",
    r."LMG",
    r."SMA",
    r."SMP",
    r."Ver",
    r."Code",
    r."Utang",
    r."Jur_S1",
    r."Jur_S2",
    r."Jur_S3",
    r."Mentor",
    r."Piutang",
    r."Univ_S1",
    r."Univ_S2",
    r."Univ_S3",
    r."Tabungan",
    r."Th_Lahir",
    r."Bln_Lahir",
    r."Jur_D1_D4",
    r."Pesantren",
    r."Tgl_Lahir",
    r."Gelar_Awal",
    r."Univ_D1_D4",
    r."Usia_Lahir",
    r."Gelar_Akhir",
    r."Status_Nikah",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Tgl_Integrasi",
    r."Usia_Integrasi",
    r."Alamat_Provinsi",
    r."Jenis_Pekerjaan",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    r."Jabatan_Pekerjaan",
    r."Keahlian_Khusus_A",
    r."Keahlian_Khusus_B",
    r."Keahlian_Khusus_C",
    r."Keahlian_Khusus_D",
    r."Keahlian_Khusus_E",
    r."Jenis_Pemberdayaan",
    r."Status_Pemberdayaan",
    r."Gaji_Rata_rata_Pekerjaan",
    r."Aset_Hak_Milik_Mobil__Rp_",
    r."Aset_Hak_Milik_Motor__Rp_",
    r."Aset_Hak_Milik_Rumah__m2_",
    r."Aset_Hak_Milik_Tanah__m2_",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    'A2'::text AS kantor_id
   FROM (public.raw_a2 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.stg_a2_capil OWNER TO admin;

--
-- TOC entry 300 (class 1259 OID 329243)
-- Name: stg_a3_capil; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_a3_capil AS
 WITH latest_pull AS (
         SELECT max(raw_a3._airbyte_generation_id) AS last_generation_id
           FROM public.raw_a3
        )
 SELECT r."K",
    r."JK",
    r."SD",
    r."LMG",
    r."SMA",
    r."SMP",
    r."Ver",
    r."Code",
    r."Utang",
    r."Jur_S1",
    r."Jur_S2",
    r."Jur_S3",
    r."Mentor",
    r."Piutang",
    r."Univ_S1",
    r."Univ_S2",
    r."Univ_S3",
    r."Tabungan",
    r."Th_Lahir",
    r."Bln_Lahir",
    r."Jur_D1_D4",
    r."Pesantren",
    r."Tgl_Lahir",
    r."Gelar_Awal",
    r."Univ_D1_D4",
    r."Usia_Lahir",
    r."Gelar_Akhir",
    r."Status_Nikah",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Tgl_Integrasi",
    r."Usia_Integrasi",
    r."Alamat_Provinsi",
    r."Jenis_Pekerjaan",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    r."Jabatan_Pekerjaan",
    r."Keahlian_Khusus_A",
    r."Keahlian_Khusus_B",
    r."Keahlian_Khusus_C",
    r."Keahlian_Khusus_D",
    r."Keahlian_Khusus_E",
    r."Jenis_Pemberdayaan",
    r."Status_Pemberdayaan",
    r."Gaji_Rata_rata_Pekerjaan",
    r."Aset_Hak_Milik_Mobil__Rp_",
    r."Aset_Hak_Milik_Motor__Rp_",
    r."Aset_Hak_Milik_Rumah__m2_",
    r."Aset_Hak_Milik_Tanah__m2_",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    'A3'::text AS kantor_id
   FROM (public.raw_a3 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.stg_a3_capil OWNER TO admin;

--
-- TOC entry 305 (class 1259 OID 329268)
-- Name: stg_b1_capil; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_b1_capil AS
 WITH latest_pull AS (
         SELECT max(raw_b1._airbyte_generation_id) AS last_generation_id
           FROM public.raw_b1
        )
 SELECT r."K",
    r."JK",
    r."SD",
    r."LMG",
    r."SMA",
    r."SMP",
    r."Ver",
    r."Code",
    r."Utang",
    r."Jur_S1",
    r."Jur_S2",
    r."Jur_S3",
    r."Mentor",
    r."Piutang",
    r."Univ_S1",
    r."Univ_S2",
    r."Univ_S3",
    r."Tabungan",
    r."Th_Lahir",
    r."Bln_Lahir",
    r."Jur_D1_D4",
    r."Pesantren",
    r."Tgl_Lahir",
    r."Gelar_Awal",
    r."Univ_D1_D4",
    r."Usia_Lahir",
    r."Gelar_Akhir",
    r."Status_Nikah",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Tgl_Integrasi",
    r."Usia_Integrasi",
    r."Alamat_Provinsi",
    r."Jenis_Pekerjaan",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    r."Jabatan_Pekerjaan",
    r."Keahlian_Khusus_A",
    r."Keahlian_Khusus_B",
    r."Keahlian_Khusus_C",
    r."Keahlian_Khusus_D",
    r."Keahlian_Khusus_E",
    r."Jenis_Pemberdayaan",
    r."Status_Pemberdayaan",
    r."Gaji_Rata_rata_Pekerjaan",
    r."Aset_Hak_Milik_Mobil__Rp_",
    r."Aset_Hak_Milik_Motor__Rp_",
    r."Aset_Hak_Milik_Rumah__m2_",
    r."Aset_Hak_Milik_Tanah__m2_",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    'B1'::text AS kantor_id
   FROM (public.raw_b1 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.stg_b1_capil OWNER TO admin;

--
-- TOC entry 307 (class 1259 OID 329282)
-- Name: stg_b2_capil; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_b2_capil AS
 WITH latest_pull AS (
         SELECT max(raw_b2._airbyte_generation_id) AS last_generation_id
           FROM public.raw_b2
        )
 SELECT r."K",
    r."JK",
    r."SD",
    r."LMG",
    r."SMA",
    r."SMP",
    r."Ver",
    r."Code",
    r."Utang",
    r."Jur_S1",
    r."Jur_S2",
    r."Jur_S3",
    r."Mentor",
    r."Piutang",
    r."Univ_S1",
    r."Univ_S2",
    r."Univ_S3",
    r."Tabungan",
    r."Th_Lahir",
    r."Bln_Lahir",
    r."Jur_D1_D4",
    r."Pesantren",
    r."Tgl_Lahir",
    r."Gelar_Awal",
    r."Univ_D1_D4",
    r."Usia_Lahir",
    r."Gelar_Akhir",
    r."Status_Nikah",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Tgl_Integrasi",
    r."Usia_Integrasi",
    r."Alamat_Provinsi",
    r."Jenis_Pekerjaan",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    r."Jabatan_Pekerjaan",
    r."Keahlian_Khusus_A",
    r."Keahlian_Khusus_B",
    r."Keahlian_Khusus_C",
    r."Keahlian_Khusus_D",
    r."Keahlian_Khusus_E",
    r."Jenis_Pemberdayaan",
    r."Status_Pemberdayaan",
    r."Gaji_Rata_rata_Pekerjaan",
    r."Aset_Hak_Milik_Mobil__Rp_",
    r."Aset_Hak_Milik_Motor__Rp_",
    r."Aset_Hak_Milik_Rumah__m2_",
    r."Aset_Hak_Milik_Tanah__m2_",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    'B2'::text AS kantor_id
   FROM (public.raw_b2 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.stg_b2_capil OWNER TO admin;

--
-- TOC entry 309 (class 1259 OID 329292)
-- Name: stg_b3_capil; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_b3_capil AS
 WITH latest_pull AS (
         SELECT max(raw_b3._airbyte_generation_id) AS last_generation_id
           FROM public.raw_b3
        )
 SELECT r."K",
    r."JK",
    r."SD",
    r."LMG",
    r."SMA",
    r."SMP",
    r."Ver",
    r."Code",
    r."Utang",
    r."Jur_S1",
    r."Jur_S2",
    r."Jur_S3",
    r."Mentor",
    r."Piutang",
    r."Univ_S1",
    r."Univ_S2",
    r."Univ_S3",
    r."Tabungan",
    r."Th_Lahir",
    r."Bln_Lahir",
    r."Jur_D1_D4",
    r."Pesantren",
    r."Tgl_Lahir",
    r."Gelar_Awal",
    r."Univ_D1_D4",
    r."Usia_Lahir",
    r."Gelar_Akhir",
    r."Status_Nikah",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Tgl_Integrasi",
    r."Usia_Integrasi",
    r."Alamat_Provinsi",
    r."Jenis_Pekerjaan",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    r."Jabatan_Pekerjaan",
    r."Keahlian_Khusus_A",
    r."Keahlian_Khusus_B",
    r."Keahlian_Khusus_C",
    r."Keahlian_Khusus_D",
    r."Keahlian_Khusus_E",
    r."Jenis_Pemberdayaan",
    r."Status_Pemberdayaan",
    r."Gaji_Rata_rata_Pekerjaan",
    r."Aset_Hak_Milik_Mobil__Rp_",
    r."Aset_Hak_Milik_Motor__Rp_",
    r."Aset_Hak_Milik_Rumah__m2_",
    r."Aset_Hak_Milik_Tanah__m2_",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    'B3'::text AS kantor_id
   FROM (public.raw_b3 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.stg_b3_capil OWNER TO admin;

--
-- TOC entry 314 (class 1259 OID 329315)
-- Name: stg_b4_capil; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_b4_capil AS
 WITH latest_pull AS (
         SELECT max(raw_b4._airbyte_generation_id) AS last_generation_id
           FROM public.raw_b4
        )
 SELECT r."K",
    r."JK",
    r."SD",
    r."LMG",
    r."SMA",
    r."SMP",
    r."Ver",
    r."Code",
    r."Utang",
    r."Jur_S1",
    r."Jur_S2",
    r."Jur_S3",
    r."Mentor",
    r."Piutang",
    r."Univ_S1",
    r."Univ_S2",
    r."Univ_S3",
    r."Tabungan",
    r."Th_Lahir",
    r."Bln_Lahir",
    r."Jur_D1_D4",
    r."Pesantren",
    r."Tgl_Lahir",
    r."Gelar_Awal",
    r."Univ_D1_D4",
    r."Usia_Lahir",
    r."Gelar_Akhir",
    r."Status_Nikah",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Tgl_Integrasi",
    r."Usia_Integrasi",
    r."Alamat_Provinsi",
    r."Jenis_Pekerjaan",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    r."Jabatan_Pekerjaan",
    r."Keahlian_Khusus_A",
    r."Keahlian_Khusus_B",
    r."Keahlian_Khusus_C",
    r."Keahlian_Khusus_D",
    r."Keahlian_Khusus_E",
    r."Jenis_Pemberdayaan",
    r."Status_Pemberdayaan",
    r."Gaji_Rata_rata_Pekerjaan",
    r."Aset_Hak_Milik_Mobil__Rp_",
    r."Aset_Hak_Milik_Motor__Rp_",
    r."Aset_Hak_Milik_Rumah__m2_",
    r."Aset_Hak_Milik_Tanah__m2_",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    'B4'::text AS kantor_id
   FROM (public.raw_b4 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.stg_b4_capil OWNER TO admin;

--
-- TOC entry 316 (class 1259 OID 329327)
-- Name: stg_b5_capil; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_b5_capil AS
 WITH latest_pull AS (
         SELECT max(raw_b5._airbyte_generation_id) AS last_generation_id
           FROM public.raw_b5
        )
 SELECT r."K",
    r."JK",
    r."SD",
    r."LMG",
    r."SMA",
    r."SMP",
    r."Ver",
    r."Code",
    r."Utang",
    r."Jur_S1",
    r."Jur_S2",
    r."Jur_S3",
    r."Mentor",
    r."Piutang",
    r."Univ_S1",
    r."Univ_S2",
    r."Univ_S3",
    r."Tabungan",
    r."Th_Lahir",
    r."Bln_Lahir",
    r."Jur_D1_D4",
    r."Pesantren",
    r."Tgl_Lahir",
    r."Gelar_Awal",
    r."Univ_D1_D4",
    r."Usia_Lahir",
    r."Gelar_Akhir",
    r."Status_Nikah",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Tgl_Integrasi",
    r."Usia_Integrasi",
    r."Alamat_Provinsi",
    r."Jenis_Pekerjaan",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    r."Jabatan_Pekerjaan",
    r."Keahlian_Khusus_A",
    r."Keahlian_Khusus_B",
    r."Keahlian_Khusus_C",
    r."Keahlian_Khusus_D",
    r."Keahlian_Khusus_E",
    r."Jenis_Pemberdayaan",
    r."Status_Pemberdayaan",
    r."Gaji_Rata_rata_Pekerjaan",
    r."Aset_Hak_Milik_Mobil__Rp_",
    r."Aset_Hak_Milik_Motor__Rp_",
    r."Aset_Hak_Milik_Rumah__m2_",
    r."Aset_Hak_Milik_Tanah__m2_",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    'B5'::text AS kantor_id
   FROM (public.raw_b5 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.stg_b5_capil OWNER TO admin;

--
-- TOC entry 319 (class 1259 OID 329342)
-- Name: stg_c1_capil; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_c1_capil AS
 WITH latest_pull AS (
         SELECT max(raw_c1._airbyte_generation_id) AS last_generation_id
           FROM public.raw_c1
        )
 SELECT r."K",
    r."JK",
    r."SD",
    r."LMG",
    r."SMA",
    r."SMP",
    r."Ver",
    r."Code",
    r."Utang",
    r."Jur_S1",
    r."Jur_S2",
    r."Jur_S3",
    r."Mentor",
    r."Piutang",
    r."Univ_S1",
    r."Univ_S2",
    r."Univ_S3",
    r."Tabungan",
    r."Th_Lahir",
    r."Bln_Lahir",
    r."Jur_D1_D4",
    r."Pesantren",
    r."Tgl_Lahir",
    r."Gelar_Awal",
    r."Univ_D1_D4",
    r."Usia_Lahir",
    r."Gelar_Akhir",
    r."Status_Nikah",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Tgl_Integrasi",
    r."Usia_Integrasi",
    r."Alamat_Provinsi",
    r."Jenis_Pekerjaan",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    r."Jabatan_Pekerjaan",
    r."Keahlian_Khusus_A",
    r."Keahlian_Khusus_B",
    r."Keahlian_Khusus_C",
    r."Keahlian_Khusus_D",
    r."Keahlian_Khusus_E",
    r."Jenis_Pemberdayaan",
    r."Status_Pemberdayaan",
    r."Gaji_Rata_rata_Pekerjaan",
    r."Aset_Hak_Milik_Mobil__Rp_",
    r."Aset_Hak_Milik_Motor__Rp_",
    r."Aset_Hak_Milik_Rumah__m2_",
    r."Aset_Hak_Milik_Tanah__m2_",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    'C1'::text AS kantor_id
   FROM (public.raw_c1 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.stg_c1_capil OWNER TO admin;

--
-- TOC entry 321 (class 1259 OID 329352)
-- Name: stg_c2_capil; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_c2_capil AS
 WITH latest_pull AS (
         SELECT max(raw_c2._airbyte_generation_id) AS last_generation_id
           FROM public.raw_c2
        )
 SELECT r."K",
    r."JK",
    r."SD",
    r."LMG",
    r."SMA",
    r."SMP",
    r."Ver",
    r."Code",
    r."Utang",
    r."Jur_S1",
    r."Jur_S2",
    r."Jur_S3",
    r."Mentor",
    r."Piutang",
    r."Univ_S1",
    r."Univ_S2",
    r."Univ_S3",
    r."Tabungan",
    r."Th_Lahir",
    r."Bln_Lahir",
    r."Jur_D1_D4",
    r."Pesantren",
    r."Tgl_Lahir",
    r."Gelar_Awal",
    r."Univ_D1_D4",
    r."Usia_Lahir",
    r."Gelar_Akhir",
    r."Status_Nikah",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Tgl_Integrasi",
    r."Usia_Integrasi",
    r."Alamat_Provinsi",
    r."Jenis_Pekerjaan",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    r."Jabatan_Pekerjaan",
    r."Keahlian_Khusus_A",
    r."Keahlian_Khusus_B",
    r."Keahlian_Khusus_C",
    r."Keahlian_Khusus_D",
    r."Keahlian_Khusus_E",
    r."Jenis_Pemberdayaan",
    r."Status_Pemberdayaan",
    r."Gaji_Rata_rata_Pekerjaan",
    r."Aset_Hak_Milik_Mobil__Rp_",
    r."Aset_Hak_Milik_Motor__Rp_",
    r."Aset_Hak_Milik_Rumah__m2_",
    r."Aset_Hak_Milik_Tanah__m2_",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    'C2'::text AS kantor_id
   FROM (public.raw_c2 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.stg_c2_capil OWNER TO admin;

--
-- TOC entry 325 (class 1259 OID 329372)
-- Name: stg_c3_capil; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_c3_capil AS
 WITH latest_pull AS (
         SELECT max(raw_c3._airbyte_generation_id) AS last_generation_id
           FROM public.raw_c3
        )
 SELECT r."K",
    r."JK",
    r."SD",
    r."LMG",
    r."SMA",
    r."SMP",
    r."Ver",
    r."Code",
    r."Utang",
    r."Jur_S1",
    r."Jur_S2",
    r."Jur_S3",
    r."Mentor",
    r."Piutang",
    r."Univ_S1",
    r."Univ_S2",
    r."Univ_S3",
    r."Tabungan",
    r."Th_Lahir",
    r."Bln_Lahir",
    r."Jur_D1_D4",
    r."Pesantren",
    r."Tgl_Lahir",
    r."Gelar_Awal",
    r."Univ_D1_D4",
    r."Usia_Lahir",
    r."Gelar_Akhir",
    r."Status_Nikah",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Tgl_Integrasi",
    r."Usia_Integrasi",
    r."Alamat_Provinsi",
    r."Jenis_Pekerjaan",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    r."Jabatan_Pekerjaan",
    r."Keahlian_Khusus_A",
    r."Keahlian_Khusus_B",
    r."Keahlian_Khusus_C",
    r."Keahlian_Khusus_D",
    r."Keahlian_Khusus_E",
    r."Jenis_Pemberdayaan",
    r."Status_Pemberdayaan",
    r."Gaji_Rata_rata_Pekerjaan",
    r."Aset_Hak_Milik_Mobil__Rp_",
    r."Aset_Hak_Milik_Motor__Rp_",
    r."Aset_Hak_Milik_Rumah__m2_",
    r."Aset_Hak_Milik_Tanah__m2_",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    'C3'::text AS kantor_id
   FROM (public.raw_c3 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.stg_c3_capil OWNER TO admin;

--
-- TOC entry 327 (class 1259 OID 329381)
-- Name: stg_c4_capil; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_c4_capil AS
 WITH latest_pull AS (
         SELECT max(raw_c4._airbyte_generation_id) AS last_generation_id
           FROM public.raw_c4
        )
 SELECT r."K",
    r."JK",
    r."SD",
    r."LMG",
    r."SMA",
    r."SMP",
    r."Ver",
    r."Code",
    r."Utang",
    r."Jur_S1",
    r."Jur_S2",
    r."Jur_S3",
    r."Mentor",
    r."Piutang",
    r."Univ_S1",
    r."Univ_S2",
    r."Univ_S3",
    r."Tabungan",
    r."Th_Lahir",
    r."Bln_Lahir",
    r."Jur_D1_D4",
    r."Pesantren",
    r."Tgl_Lahir",
    r."Gelar_Awal",
    r."Univ_D1_D4",
    r."Usia_Lahir",
    r."Gelar_Akhir",
    r."Status_Nikah",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Tgl_Integrasi",
    r."Usia_Integrasi",
    r."Alamat_Provinsi",
    r."Jenis_Pekerjaan",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    r."Jabatan_Pekerjaan",
    r."Keahlian_Khusus_A",
    r."Keahlian_Khusus_B",
    r."Keahlian_Khusus_C",
    r."Keahlian_Khusus_D",
    r."Keahlian_Khusus_E",
    r."Jenis_Pemberdayaan",
    r."Status_Pemberdayaan",
    r."Gaji_Rata_rata_Pekerjaan",
    r."Aset_Hak_Milik_Mobil__Rp_",
    r."Aset_Hak_Milik_Motor__Rp_",
    r."Aset_Hak_Milik_Rumah__m2_",
    r."Aset_Hak_Milik_Tanah__m2_",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    'C4'::text AS kantor_id
   FROM (public.raw_c4 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.stg_c4_capil OWNER TO admin;

--
-- TOC entry 231 (class 1259 OID 33307)
-- Name: raw_c5; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_c5 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "K" character varying,
    "JK" character varying,
    "SD" character varying,
    "LMG" character varying,
    "No_" numeric,
    "SMA" character varying,
    "SMP" character varying,
    "Ver" character varying,
    "Code" character varying,
    "null" character varying,
    "Utang" character varying,
    "Jur_S1" character varying,
    "Jur_S2" character varying,
    "Jur_S3" character varying,
    "Mentor" character varying,
    "Piutang" character varying,
    "Univ_S1" character varying,
    "Univ_S2" character varying,
    "Univ_S3" character varying,
    "Tabungan" character varying,
    "Th_Lahir" character varying,
    "Bln_Lahir" character varying,
    "Jur_D1_D4" character varying,
    "Pesantren" character varying,
    "Tgl_Lahir" character varying,
    "Gelar_Awal" character varying,
    "Univ_D1_D4" character varying,
    "Usia_Lahir" character varying,
    "Gelar_Akhir" character varying,
    "Status_Nikah" character varying,
    "Th_Integrasi" character varying,
    "Alamat_Negara" character varying,
    "Bln_Integrasi" character varying,
    "Tgl_Integrasi" character varying,
    "Usia_Integrasi" character varying,
    "Alamat_Provinsi" character varying,
    "Jenis_Pekerjaan" character varying,
    "Status_Tabungan" character varying,
    "Alamat_Kabupaten" character varying,
    "Alamat_Kecamatan" character varying,
    "Status_Aktivitas" character varying,
    "Jabatan_Pekerjaan" character varying,
    "Keahlian_Khusus_A" character varying,
    "Keahlian_Khusus_B" character varying,
    "Keahlian_Khusus_C" character varying,
    "Keahlian_Khusus_D" character varying,
    "Keahlian_Khusus_E" character varying,
    "Jenis_Pemberdayaan" character varying,
    "Status_Pemberdayaan" character varying,
    "Gaji_Rata_rata_Pekerjaan" character varying,
    "Aset_Hak_Milik_Mobil__Rp_" character varying,
    "Aset_Hak_Milik_Motor__Rp_" character varying,
    "Aset_Hak_Milik_Rumah__m2_" character varying,
    "Aset_Hak_Milik_Tanah__m2_" character varying
);


ALTER TABLE public.raw_c5 OWNER TO admin;

--
-- TOC entry 331 (class 1259 OID 329402)
-- Name: stg_c5_capil; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_c5_capil AS
 WITH latest_pull AS (
         SELECT max(raw_c5._airbyte_generation_id) AS last_generation_id
           FROM public.raw_c5
        )
 SELECT r."K",
    r."JK",
    r."SD",
    r."LMG",
    r."SMA",
    r."SMP",
    r."Ver",
    r."Code",
    r."Utang",
    r."Jur_S1",
    r."Jur_S2",
    r."Jur_S3",
    r."Mentor",
    r."Piutang",
    r."Univ_S1",
    r."Univ_S2",
    r."Univ_S3",
    r."Tabungan",
    r."Th_Lahir",
    r."Bln_Lahir",
    r."Jur_D1_D4",
    r."Pesantren",
    r."Tgl_Lahir",
    r."Gelar_Awal",
    r."Univ_D1_D4",
    r."Usia_Lahir",
    r."Gelar_Akhir",
    r."Status_Nikah",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Tgl_Integrasi",
    r."Usia_Integrasi",
    r."Alamat_Provinsi",
    r."Jenis_Pekerjaan",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    r."Jabatan_Pekerjaan",
    r."Keahlian_Khusus_A",
    r."Keahlian_Khusus_B",
    r."Keahlian_Khusus_C",
    r."Keahlian_Khusus_D",
    r."Keahlian_Khusus_E",
    r."Jenis_Pemberdayaan",
    r."Status_Pemberdayaan",
    r."Gaji_Rata_rata_Pekerjaan",
    r."Aset_Hak_Milik_Mobil__Rp_",
    r."Aset_Hak_Milik_Motor__Rp_",
    r."Aset_Hak_Milik_Rumah__m2_",
    r."Aset_Hak_Milik_Tanah__m2_",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    'C5'::text AS kantor_id
   FROM (public.raw_c5 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.stg_c5_capil OWNER TO admin;

--
-- TOC entry 232 (class 1259 OID 33326)
-- Name: raw_c6; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_c6 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "K" character varying,
    "JK" character varying,
    "SD" character varying,
    "LMG" character varying,
    "No_" numeric,
    "SMA" character varying,
    "SMP" character varying,
    "Ver" character varying,
    "Code" character varying,
    "null" character varying,
    "Utang" character varying,
    "Jur_S1" character varying,
    "Jur_S2" character varying,
    "Jur_S3" character varying,
    "Mentor" character varying,
    "Piutang" character varying,
    "Univ_S1" character varying,
    "Univ_S2" character varying,
    "Univ_S3" character varying,
    "Tabungan" character varying,
    "Th_Lahir" character varying,
    "Bln_Lahir" character varying,
    "Jur_D1_D4" character varying,
    "Pesantren" character varying,
    "Tgl_Lahir" character varying,
    "Gelar_Awal" character varying,
    "Univ_D1_D4" character varying,
    "Usia_Lahir" character varying,
    "Gelar_Akhir" character varying,
    "Status_Nikah" character varying,
    "Th_Integrasi" character varying,
    "Alamat_Negara" character varying,
    "Bln_Integrasi" character varying,
    "Tgl_Integrasi" character varying,
    "Usia_Integrasi" character varying,
    "Alamat_Provinsi" character varying,
    "Jenis_Pekerjaan" character varying,
    "Status_Tabungan" character varying,
    "Alamat_Kabupaten" character varying,
    "Alamat_Kecamatan" character varying,
    "Status_Aktivitas" character varying,
    "Jabatan_Pekerjaan" character varying,
    "Keahlian_Khusus_A" character varying,
    "Keahlian_Khusus_B" character varying,
    "Keahlian_Khusus_C" character varying,
    "Keahlian_Khusus_D" character varying,
    "Keahlian_Khusus_E" character varying,
    "Jenis_Pemberdayaan" character varying,
    "Status_Pemberdayaan" character varying,
    "Gaji_Rata_rata_Pekerjaan" character varying,
    "Aset_Hak_Milik_Mobil__Rp_" character varying,
    "Aset_Hak_Milik_Motor__Rp_" character varying,
    "Aset_Hak_Milik_Rumah__m2_" character varying,
    "Aset_Hak_Milik_Tanah__m2_" character varying
);


ALTER TABLE public.raw_c6 OWNER TO admin;

--
-- TOC entry 333 (class 1259 OID 329412)
-- Name: stg_c6_capil; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_c6_capil AS
 WITH latest_pull AS (
         SELECT max(raw_c6._airbyte_generation_id) AS last_generation_id
           FROM public.raw_c6
        )
 SELECT r."K",
    r."JK",
    r."SD",
    r."LMG",
    r."SMA",
    r."SMP",
    r."Ver",
    r."Code",
    r."Utang",
    r."Jur_S1",
    r."Jur_S2",
    r."Jur_S3",
    r."Mentor",
    r."Piutang",
    r."Univ_S1",
    r."Univ_S2",
    r."Univ_S3",
    r."Tabungan",
    r."Th_Lahir",
    r."Bln_Lahir",
    r."Jur_D1_D4",
    r."Pesantren",
    r."Tgl_Lahir",
    r."Gelar_Awal",
    r."Univ_D1_D4",
    r."Usia_Lahir",
    r."Gelar_Akhir",
    r."Status_Nikah",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Tgl_Integrasi",
    r."Usia_Integrasi",
    r."Alamat_Provinsi",
    r."Jenis_Pekerjaan",
    r."Status_Tabungan",
    r."Status_Aktivitas",
    r."Jabatan_Pekerjaan",
    r."Keahlian_Khusus_A",
    r."Keahlian_Khusus_B",
    r."Keahlian_Khusus_C",
    r."Keahlian_Khusus_D",
    r."Keahlian_Khusus_E",
    r."Jenis_Pemberdayaan",
    r."Status_Pemberdayaan",
    r."Gaji_Rata_rata_Pekerjaan",
    r."Aset_Hak_Milik_Mobil__Rp_",
    r."Aset_Hak_Milik_Motor__Rp_",
    r."Aset_Hak_Milik_Rumah__m2_",
    r."Aset_Hak_Milik_Tanah__m2_",
    lower((r."Alamat_Negara")::text) AS "Alamat_Negara",
    lower((r."Alamat_Kabupaten")::text) AS "Alamat_Kabupaten",
    lower((r."Alamat_Kecamatan")::text) AS "Alamat_Kecamatan",
    'C6'::text AS kantor_id
   FROM (public.raw_c6 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
  WHERE (r."K" IS NOT NULL);


ALTER VIEW analytics.stg_c6_capil OWNER TO admin;

--
-- TOC entry 336 (class 1259 OID 329427)
-- Name: mart_capil; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.mart_capil AS
 SELECT stg_a1_capil."K",
    stg_a1_capil."JK",
    stg_a1_capil."SD",
    stg_a1_capil."LMG",
    stg_a1_capil."SMA",
    stg_a1_capil."SMP",
    stg_a1_capil."Ver",
    stg_a1_capil."Code",
    stg_a1_capil."Utang",
    stg_a1_capil."Jur_S1",
    stg_a1_capil."Jur_S2",
    stg_a1_capil."Jur_S3",
    stg_a1_capil."Mentor",
    stg_a1_capil."Piutang",
    stg_a1_capil."Univ_S1",
    stg_a1_capil."Univ_S2",
    stg_a1_capil."Univ_S3",
    stg_a1_capil."Tabungan",
    stg_a1_capil."Th_Lahir",
    stg_a1_capil."Bln_Lahir",
    stg_a1_capil."Jur_D1_D4",
    stg_a1_capil."Pesantren",
    stg_a1_capil."Tgl_Lahir",
    stg_a1_capil."Gelar_Awal",
    stg_a1_capil."Univ_D1_D4",
    stg_a1_capil."Usia_Lahir",
    stg_a1_capil."Gelar_Akhir",
    stg_a1_capil."Status_Nikah",
    stg_a1_capil."Th_Integrasi",
    stg_a1_capil."Bln_Integrasi",
    stg_a1_capil."Tgl_Integrasi",
    stg_a1_capil."Usia_Integrasi",
    stg_a1_capil."Alamat_Provinsi",
    stg_a1_capil."Jenis_Pekerjaan",
    stg_a1_capil."Status_Tabungan",
    stg_a1_capil."Status_Aktivitas",
    stg_a1_capil."Jabatan_Pekerjaan",
    stg_a1_capil."Keahlian_Khusus_A",
    stg_a1_capil."Keahlian_Khusus_B",
    stg_a1_capil."Keahlian_Khusus_C",
    stg_a1_capil."Keahlian_Khusus_D",
    stg_a1_capil."Keahlian_Khusus_E",
    stg_a1_capil."Jenis_Pemberdayaan",
    stg_a1_capil."Status_Pemberdayaan",
    stg_a1_capil."Gaji_Rata_rata_Pekerjaan",
    stg_a1_capil."Aset_Hak_Milik_Mobil__Rp_",
    stg_a1_capil."Aset_Hak_Milik_Motor__Rp_",
    stg_a1_capil."Aset_Hak_Milik_Rumah__m2_",
    stg_a1_capil."Aset_Hak_Milik_Tanah__m2_",
    stg_a1_capil."Alamat_Negara",
    stg_a1_capil."Alamat_Kabupaten",
    stg_a1_capil."Alamat_Kecamatan",
    stg_a1_capil.kantor_id
   FROM analytics.stg_a1_capil
UNION ALL
 SELECT stg_a2_capil."K",
    stg_a2_capil."JK",
    stg_a2_capil."SD",
    stg_a2_capil."LMG",
    stg_a2_capil."SMA",
    stg_a2_capil."SMP",
    stg_a2_capil."Ver",
    stg_a2_capil."Code",
    stg_a2_capil."Utang",
    stg_a2_capil."Jur_S1",
    stg_a2_capil."Jur_S2",
    stg_a2_capil."Jur_S3",
    stg_a2_capil."Mentor",
    stg_a2_capil."Piutang",
    stg_a2_capil."Univ_S1",
    stg_a2_capil."Univ_S2",
    stg_a2_capil."Univ_S3",
    stg_a2_capil."Tabungan",
    stg_a2_capil."Th_Lahir",
    stg_a2_capil."Bln_Lahir",
    stg_a2_capil."Jur_D1_D4",
    stg_a2_capil."Pesantren",
    stg_a2_capil."Tgl_Lahir",
    stg_a2_capil."Gelar_Awal",
    stg_a2_capil."Univ_D1_D4",
    stg_a2_capil."Usia_Lahir",
    stg_a2_capil."Gelar_Akhir",
    stg_a2_capil."Status_Nikah",
    stg_a2_capil."Th_Integrasi",
    stg_a2_capil."Bln_Integrasi",
    stg_a2_capil."Tgl_Integrasi",
    stg_a2_capil."Usia_Integrasi",
    stg_a2_capil."Alamat_Provinsi",
    stg_a2_capil."Jenis_Pekerjaan",
    stg_a2_capil."Status_Tabungan",
    stg_a2_capil."Status_Aktivitas",
    stg_a2_capil."Jabatan_Pekerjaan",
    stg_a2_capil."Keahlian_Khusus_A",
    stg_a2_capil."Keahlian_Khusus_B",
    stg_a2_capil."Keahlian_Khusus_C",
    stg_a2_capil."Keahlian_Khusus_D",
    stg_a2_capil."Keahlian_Khusus_E",
    stg_a2_capil."Jenis_Pemberdayaan",
    stg_a2_capil."Status_Pemberdayaan",
    stg_a2_capil."Gaji_Rata_rata_Pekerjaan",
    stg_a2_capil."Aset_Hak_Milik_Mobil__Rp_",
    stg_a2_capil."Aset_Hak_Milik_Motor__Rp_",
    stg_a2_capil."Aset_Hak_Milik_Rumah__m2_",
    stg_a2_capil."Aset_Hak_Milik_Tanah__m2_",
    stg_a2_capil."Alamat_Negara",
    stg_a2_capil."Alamat_Kabupaten",
    stg_a2_capil."Alamat_Kecamatan",
    stg_a2_capil.kantor_id
   FROM analytics.stg_a2_capil
UNION ALL
 SELECT stg_a3_capil."K",
    stg_a3_capil."JK",
    stg_a3_capil."SD",
    stg_a3_capil."LMG",
    stg_a3_capil."SMA",
    stg_a3_capil."SMP",
    stg_a3_capil."Ver",
    stg_a3_capil."Code",
    stg_a3_capil."Utang",
    stg_a3_capil."Jur_S1",
    stg_a3_capil."Jur_S2",
    stg_a3_capil."Jur_S3",
    stg_a3_capil."Mentor",
    stg_a3_capil."Piutang",
    stg_a3_capil."Univ_S1",
    stg_a3_capil."Univ_S2",
    stg_a3_capil."Univ_S3",
    stg_a3_capil."Tabungan",
    stg_a3_capil."Th_Lahir",
    stg_a3_capil."Bln_Lahir",
    stg_a3_capil."Jur_D1_D4",
    stg_a3_capil."Pesantren",
    stg_a3_capil."Tgl_Lahir",
    stg_a3_capil."Gelar_Awal",
    stg_a3_capil."Univ_D1_D4",
    stg_a3_capil."Usia_Lahir",
    stg_a3_capil."Gelar_Akhir",
    stg_a3_capil."Status_Nikah",
    stg_a3_capil."Th_Integrasi",
    stg_a3_capil."Bln_Integrasi",
    stg_a3_capil."Tgl_Integrasi",
    stg_a3_capil."Usia_Integrasi",
    stg_a3_capil."Alamat_Provinsi",
    stg_a3_capil."Jenis_Pekerjaan",
    stg_a3_capil."Status_Tabungan",
    stg_a3_capil."Status_Aktivitas",
    stg_a3_capil."Jabatan_Pekerjaan",
    stg_a3_capil."Keahlian_Khusus_A",
    stg_a3_capil."Keahlian_Khusus_B",
    stg_a3_capil."Keahlian_Khusus_C",
    stg_a3_capil."Keahlian_Khusus_D",
    stg_a3_capil."Keahlian_Khusus_E",
    stg_a3_capil."Jenis_Pemberdayaan",
    stg_a3_capil."Status_Pemberdayaan",
    stg_a3_capil."Gaji_Rata_rata_Pekerjaan",
    stg_a3_capil."Aset_Hak_Milik_Mobil__Rp_",
    stg_a3_capil."Aset_Hak_Milik_Motor__Rp_",
    stg_a3_capil."Aset_Hak_Milik_Rumah__m2_",
    stg_a3_capil."Aset_Hak_Milik_Tanah__m2_",
    stg_a3_capil."Alamat_Negara",
    stg_a3_capil."Alamat_Kabupaten",
    stg_a3_capil."Alamat_Kecamatan",
    stg_a3_capil.kantor_id
   FROM analytics.stg_a3_capil
UNION ALL
 SELECT stg_b1_capil."K",
    stg_b1_capil."JK",
    stg_b1_capil."SD",
    stg_b1_capil."LMG",
    stg_b1_capil."SMA",
    stg_b1_capil."SMP",
    stg_b1_capil."Ver",
    stg_b1_capil."Code",
    stg_b1_capil."Utang",
    stg_b1_capil."Jur_S1",
    stg_b1_capil."Jur_S2",
    stg_b1_capil."Jur_S3",
    stg_b1_capil."Mentor",
    stg_b1_capil."Piutang",
    stg_b1_capil."Univ_S1",
    stg_b1_capil."Univ_S2",
    stg_b1_capil."Univ_S3",
    stg_b1_capil."Tabungan",
    stg_b1_capil."Th_Lahir",
    stg_b1_capil."Bln_Lahir",
    stg_b1_capil."Jur_D1_D4",
    stg_b1_capil."Pesantren",
    stg_b1_capil."Tgl_Lahir",
    stg_b1_capil."Gelar_Awal",
    stg_b1_capil."Univ_D1_D4",
    stg_b1_capil."Usia_Lahir",
    stg_b1_capil."Gelar_Akhir",
    stg_b1_capil."Status_Nikah",
    stg_b1_capil."Th_Integrasi",
    stg_b1_capil."Bln_Integrasi",
    stg_b1_capil."Tgl_Integrasi",
    stg_b1_capil."Usia_Integrasi",
    stg_b1_capil."Alamat_Provinsi",
    stg_b1_capil."Jenis_Pekerjaan",
    stg_b1_capil."Status_Tabungan",
    stg_b1_capil."Status_Aktivitas",
    stg_b1_capil."Jabatan_Pekerjaan",
    stg_b1_capil."Keahlian_Khusus_A",
    stg_b1_capil."Keahlian_Khusus_B",
    stg_b1_capil."Keahlian_Khusus_C",
    stg_b1_capil."Keahlian_Khusus_D",
    stg_b1_capil."Keahlian_Khusus_E",
    stg_b1_capil."Jenis_Pemberdayaan",
    stg_b1_capil."Status_Pemberdayaan",
    stg_b1_capil."Gaji_Rata_rata_Pekerjaan",
    stg_b1_capil."Aset_Hak_Milik_Mobil__Rp_",
    stg_b1_capil."Aset_Hak_Milik_Motor__Rp_",
    stg_b1_capil."Aset_Hak_Milik_Rumah__m2_",
    stg_b1_capil."Aset_Hak_Milik_Tanah__m2_",
    stg_b1_capil."Alamat_Negara",
    stg_b1_capil."Alamat_Kabupaten",
    stg_b1_capil."Alamat_Kecamatan",
    stg_b1_capil.kantor_id
   FROM analytics.stg_b1_capil
UNION ALL
 SELECT stg_b2_capil."K",
    stg_b2_capil."JK",
    stg_b2_capil."SD",
    stg_b2_capil."LMG",
    stg_b2_capil."SMA",
    stg_b2_capil."SMP",
    stg_b2_capil."Ver",
    stg_b2_capil."Code",
    stg_b2_capil."Utang",
    stg_b2_capil."Jur_S1",
    stg_b2_capil."Jur_S2",
    stg_b2_capil."Jur_S3",
    stg_b2_capil."Mentor",
    stg_b2_capil."Piutang",
    stg_b2_capil."Univ_S1",
    stg_b2_capil."Univ_S2",
    stg_b2_capil."Univ_S3",
    stg_b2_capil."Tabungan",
    stg_b2_capil."Th_Lahir",
    stg_b2_capil."Bln_Lahir",
    stg_b2_capil."Jur_D1_D4",
    stg_b2_capil."Pesantren",
    stg_b2_capil."Tgl_Lahir",
    stg_b2_capil."Gelar_Awal",
    stg_b2_capil."Univ_D1_D4",
    stg_b2_capil."Usia_Lahir",
    stg_b2_capil."Gelar_Akhir",
    stg_b2_capil."Status_Nikah",
    stg_b2_capil."Th_Integrasi",
    stg_b2_capil."Bln_Integrasi",
    stg_b2_capil."Tgl_Integrasi",
    stg_b2_capil."Usia_Integrasi",
    stg_b2_capil."Alamat_Provinsi",
    stg_b2_capil."Jenis_Pekerjaan",
    stg_b2_capil."Status_Tabungan",
    stg_b2_capil."Status_Aktivitas",
    stg_b2_capil."Jabatan_Pekerjaan",
    stg_b2_capil."Keahlian_Khusus_A",
    stg_b2_capil."Keahlian_Khusus_B",
    stg_b2_capil."Keahlian_Khusus_C",
    stg_b2_capil."Keahlian_Khusus_D",
    stg_b2_capil."Keahlian_Khusus_E",
    stg_b2_capil."Jenis_Pemberdayaan",
    stg_b2_capil."Status_Pemberdayaan",
    stg_b2_capil."Gaji_Rata_rata_Pekerjaan",
    stg_b2_capil."Aset_Hak_Milik_Mobil__Rp_",
    stg_b2_capil."Aset_Hak_Milik_Motor__Rp_",
    stg_b2_capil."Aset_Hak_Milik_Rumah__m2_",
    stg_b2_capil."Aset_Hak_Milik_Tanah__m2_",
    stg_b2_capil."Alamat_Negara",
    stg_b2_capil."Alamat_Kabupaten",
    stg_b2_capil."Alamat_Kecamatan",
    stg_b2_capil.kantor_id
   FROM analytics.stg_b2_capil
UNION ALL
 SELECT stg_b3_capil."K",
    stg_b3_capil."JK",
    stg_b3_capil."SD",
    stg_b3_capil."LMG",
    stg_b3_capil."SMA",
    stg_b3_capil."SMP",
    stg_b3_capil."Ver",
    stg_b3_capil."Code",
    stg_b3_capil."Utang",
    stg_b3_capil."Jur_S1",
    stg_b3_capil."Jur_S2",
    stg_b3_capil."Jur_S3",
    stg_b3_capil."Mentor",
    stg_b3_capil."Piutang",
    stg_b3_capil."Univ_S1",
    stg_b3_capil."Univ_S2",
    stg_b3_capil."Univ_S3",
    stg_b3_capil."Tabungan",
    stg_b3_capil."Th_Lahir",
    stg_b3_capil."Bln_Lahir",
    stg_b3_capil."Jur_D1_D4",
    stg_b3_capil."Pesantren",
    stg_b3_capil."Tgl_Lahir",
    stg_b3_capil."Gelar_Awal",
    stg_b3_capil."Univ_D1_D4",
    stg_b3_capil."Usia_Lahir",
    stg_b3_capil."Gelar_Akhir",
    stg_b3_capil."Status_Nikah",
    stg_b3_capil."Th_Integrasi",
    stg_b3_capil."Bln_Integrasi",
    stg_b3_capil."Tgl_Integrasi",
    stg_b3_capil."Usia_Integrasi",
    stg_b3_capil."Alamat_Provinsi",
    stg_b3_capil."Jenis_Pekerjaan",
    stg_b3_capil."Status_Tabungan",
    stg_b3_capil."Status_Aktivitas",
    stg_b3_capil."Jabatan_Pekerjaan",
    stg_b3_capil."Keahlian_Khusus_A",
    stg_b3_capil."Keahlian_Khusus_B",
    stg_b3_capil."Keahlian_Khusus_C",
    stg_b3_capil."Keahlian_Khusus_D",
    stg_b3_capil."Keahlian_Khusus_E",
    stg_b3_capil."Jenis_Pemberdayaan",
    stg_b3_capil."Status_Pemberdayaan",
    stg_b3_capil."Gaji_Rata_rata_Pekerjaan",
    stg_b3_capil."Aset_Hak_Milik_Mobil__Rp_",
    stg_b3_capil."Aset_Hak_Milik_Motor__Rp_",
    stg_b3_capil."Aset_Hak_Milik_Rumah__m2_",
    stg_b3_capil."Aset_Hak_Milik_Tanah__m2_",
    stg_b3_capil."Alamat_Negara",
    stg_b3_capil."Alamat_Kabupaten",
    stg_b3_capil."Alamat_Kecamatan",
    stg_b3_capil.kantor_id
   FROM analytics.stg_b3_capil
UNION ALL
 SELECT stg_b4_capil."K",
    stg_b4_capil."JK",
    stg_b4_capil."SD",
    stg_b4_capil."LMG",
    stg_b4_capil."SMA",
    stg_b4_capil."SMP",
    stg_b4_capil."Ver",
    stg_b4_capil."Code",
    stg_b4_capil."Utang",
    stg_b4_capil."Jur_S1",
    stg_b4_capil."Jur_S2",
    stg_b4_capil."Jur_S3",
    stg_b4_capil."Mentor",
    stg_b4_capil."Piutang",
    stg_b4_capil."Univ_S1",
    stg_b4_capil."Univ_S2",
    stg_b4_capil."Univ_S3",
    stg_b4_capil."Tabungan",
    stg_b4_capil."Th_Lahir",
    stg_b4_capil."Bln_Lahir",
    stg_b4_capil."Jur_D1_D4",
    stg_b4_capil."Pesantren",
    stg_b4_capil."Tgl_Lahir",
    stg_b4_capil."Gelar_Awal",
    stg_b4_capil."Univ_D1_D4",
    stg_b4_capil."Usia_Lahir",
    stg_b4_capil."Gelar_Akhir",
    stg_b4_capil."Status_Nikah",
    stg_b4_capil."Th_Integrasi",
    stg_b4_capil."Bln_Integrasi",
    stg_b4_capil."Tgl_Integrasi",
    stg_b4_capil."Usia_Integrasi",
    stg_b4_capil."Alamat_Provinsi",
    stg_b4_capil."Jenis_Pekerjaan",
    stg_b4_capil."Status_Tabungan",
    stg_b4_capil."Status_Aktivitas",
    stg_b4_capil."Jabatan_Pekerjaan",
    stg_b4_capil."Keahlian_Khusus_A",
    stg_b4_capil."Keahlian_Khusus_B",
    stg_b4_capil."Keahlian_Khusus_C",
    stg_b4_capil."Keahlian_Khusus_D",
    stg_b4_capil."Keahlian_Khusus_E",
    stg_b4_capil."Jenis_Pemberdayaan",
    stg_b4_capil."Status_Pemberdayaan",
    stg_b4_capil."Gaji_Rata_rata_Pekerjaan",
    stg_b4_capil."Aset_Hak_Milik_Mobil__Rp_",
    stg_b4_capil."Aset_Hak_Milik_Motor__Rp_",
    stg_b4_capil."Aset_Hak_Milik_Rumah__m2_",
    stg_b4_capil."Aset_Hak_Milik_Tanah__m2_",
    stg_b4_capil."Alamat_Negara",
    stg_b4_capil."Alamat_Kabupaten",
    stg_b4_capil."Alamat_Kecamatan",
    stg_b4_capil.kantor_id
   FROM analytics.stg_b4_capil
UNION ALL
 SELECT stg_b5_capil."K",
    stg_b5_capil."JK",
    stg_b5_capil."SD",
    stg_b5_capil."LMG",
    stg_b5_capil."SMA",
    stg_b5_capil."SMP",
    stg_b5_capil."Ver",
    stg_b5_capil."Code",
    stg_b5_capil."Utang",
    stg_b5_capil."Jur_S1",
    stg_b5_capil."Jur_S2",
    stg_b5_capil."Jur_S3",
    stg_b5_capil."Mentor",
    stg_b5_capil."Piutang",
    stg_b5_capil."Univ_S1",
    stg_b5_capil."Univ_S2",
    stg_b5_capil."Univ_S3",
    stg_b5_capil."Tabungan",
    stg_b5_capil."Th_Lahir",
    stg_b5_capil."Bln_Lahir",
    stg_b5_capil."Jur_D1_D4",
    stg_b5_capil."Pesantren",
    stg_b5_capil."Tgl_Lahir",
    stg_b5_capil."Gelar_Awal",
    stg_b5_capil."Univ_D1_D4",
    stg_b5_capil."Usia_Lahir",
    stg_b5_capil."Gelar_Akhir",
    stg_b5_capil."Status_Nikah",
    stg_b5_capil."Th_Integrasi",
    stg_b5_capil."Bln_Integrasi",
    stg_b5_capil."Tgl_Integrasi",
    stg_b5_capil."Usia_Integrasi",
    stg_b5_capil."Alamat_Provinsi",
    stg_b5_capil."Jenis_Pekerjaan",
    stg_b5_capil."Status_Tabungan",
    stg_b5_capil."Status_Aktivitas",
    stg_b5_capil."Jabatan_Pekerjaan",
    stg_b5_capil."Keahlian_Khusus_A",
    stg_b5_capil."Keahlian_Khusus_B",
    stg_b5_capil."Keahlian_Khusus_C",
    stg_b5_capil."Keahlian_Khusus_D",
    stg_b5_capil."Keahlian_Khusus_E",
    stg_b5_capil."Jenis_Pemberdayaan",
    stg_b5_capil."Status_Pemberdayaan",
    stg_b5_capil."Gaji_Rata_rata_Pekerjaan",
    stg_b5_capil."Aset_Hak_Milik_Mobil__Rp_",
    stg_b5_capil."Aset_Hak_Milik_Motor__Rp_",
    stg_b5_capil."Aset_Hak_Milik_Rumah__m2_",
    stg_b5_capil."Aset_Hak_Milik_Tanah__m2_",
    stg_b5_capil."Alamat_Negara",
    stg_b5_capil."Alamat_Kabupaten",
    stg_b5_capil."Alamat_Kecamatan",
    stg_b5_capil.kantor_id
   FROM analytics.stg_b5_capil
UNION ALL
 SELECT stg_c1_capil."K",
    stg_c1_capil."JK",
    stg_c1_capil."SD",
    stg_c1_capil."LMG",
    stg_c1_capil."SMA",
    stg_c1_capil."SMP",
    stg_c1_capil."Ver",
    stg_c1_capil."Code",
    stg_c1_capil."Utang",
    stg_c1_capil."Jur_S1",
    stg_c1_capil."Jur_S2",
    stg_c1_capil."Jur_S3",
    stg_c1_capil."Mentor",
    stg_c1_capil."Piutang",
    stg_c1_capil."Univ_S1",
    stg_c1_capil."Univ_S2",
    stg_c1_capil."Univ_S3",
    stg_c1_capil."Tabungan",
    stg_c1_capil."Th_Lahir",
    stg_c1_capil."Bln_Lahir",
    stg_c1_capil."Jur_D1_D4",
    stg_c1_capil."Pesantren",
    stg_c1_capil."Tgl_Lahir",
    stg_c1_capil."Gelar_Awal",
    stg_c1_capil."Univ_D1_D4",
    stg_c1_capil."Usia_Lahir",
    stg_c1_capil."Gelar_Akhir",
    stg_c1_capil."Status_Nikah",
    stg_c1_capil."Th_Integrasi",
    stg_c1_capil."Bln_Integrasi",
    stg_c1_capil."Tgl_Integrasi",
    stg_c1_capil."Usia_Integrasi",
    stg_c1_capil."Alamat_Provinsi",
    stg_c1_capil."Jenis_Pekerjaan",
    stg_c1_capil."Status_Tabungan",
    stg_c1_capil."Status_Aktivitas",
    stg_c1_capil."Jabatan_Pekerjaan",
    stg_c1_capil."Keahlian_Khusus_A",
    stg_c1_capil."Keahlian_Khusus_B",
    stg_c1_capil."Keahlian_Khusus_C",
    stg_c1_capil."Keahlian_Khusus_D",
    stg_c1_capil."Keahlian_Khusus_E",
    stg_c1_capil."Jenis_Pemberdayaan",
    stg_c1_capil."Status_Pemberdayaan",
    stg_c1_capil."Gaji_Rata_rata_Pekerjaan",
    stg_c1_capil."Aset_Hak_Milik_Mobil__Rp_",
    stg_c1_capil."Aset_Hak_Milik_Motor__Rp_",
    stg_c1_capil."Aset_Hak_Milik_Rumah__m2_",
    stg_c1_capil."Aset_Hak_Milik_Tanah__m2_",
    stg_c1_capil."Alamat_Negara",
    stg_c1_capil."Alamat_Kabupaten",
    stg_c1_capil."Alamat_Kecamatan",
    stg_c1_capil.kantor_id
   FROM analytics.stg_c1_capil
UNION ALL
 SELECT stg_c2_capil."K",
    stg_c2_capil."JK",
    stg_c2_capil."SD",
    stg_c2_capil."LMG",
    stg_c2_capil."SMA",
    stg_c2_capil."SMP",
    stg_c2_capil."Ver",
    stg_c2_capil."Code",
    stg_c2_capil."Utang",
    stg_c2_capil."Jur_S1",
    stg_c2_capil."Jur_S2",
    stg_c2_capil."Jur_S3",
    stg_c2_capil."Mentor",
    stg_c2_capil."Piutang",
    stg_c2_capil."Univ_S1",
    stg_c2_capil."Univ_S2",
    stg_c2_capil."Univ_S3",
    stg_c2_capil."Tabungan",
    stg_c2_capil."Th_Lahir",
    stg_c2_capil."Bln_Lahir",
    stg_c2_capil."Jur_D1_D4",
    stg_c2_capil."Pesantren",
    stg_c2_capil."Tgl_Lahir",
    stg_c2_capil."Gelar_Awal",
    stg_c2_capil."Univ_D1_D4",
    stg_c2_capil."Usia_Lahir",
    stg_c2_capil."Gelar_Akhir",
    stg_c2_capil."Status_Nikah",
    stg_c2_capil."Th_Integrasi",
    stg_c2_capil."Bln_Integrasi",
    stg_c2_capil."Tgl_Integrasi",
    stg_c2_capil."Usia_Integrasi",
    stg_c2_capil."Alamat_Provinsi",
    stg_c2_capil."Jenis_Pekerjaan",
    stg_c2_capil."Status_Tabungan",
    stg_c2_capil."Status_Aktivitas",
    stg_c2_capil."Jabatan_Pekerjaan",
    stg_c2_capil."Keahlian_Khusus_A",
    stg_c2_capil."Keahlian_Khusus_B",
    stg_c2_capil."Keahlian_Khusus_C",
    stg_c2_capil."Keahlian_Khusus_D",
    stg_c2_capil."Keahlian_Khusus_E",
    stg_c2_capil."Jenis_Pemberdayaan",
    stg_c2_capil."Status_Pemberdayaan",
    stg_c2_capil."Gaji_Rata_rata_Pekerjaan",
    stg_c2_capil."Aset_Hak_Milik_Mobil__Rp_",
    stg_c2_capil."Aset_Hak_Milik_Motor__Rp_",
    stg_c2_capil."Aset_Hak_Milik_Rumah__m2_",
    stg_c2_capil."Aset_Hak_Milik_Tanah__m2_",
    stg_c2_capil."Alamat_Negara",
    stg_c2_capil."Alamat_Kabupaten",
    stg_c2_capil."Alamat_Kecamatan",
    stg_c2_capil.kantor_id
   FROM analytics.stg_c2_capil
UNION ALL
 SELECT stg_c3_capil."K",
    stg_c3_capil."JK",
    stg_c3_capil."SD",
    stg_c3_capil."LMG",
    stg_c3_capil."SMA",
    stg_c3_capil."SMP",
    stg_c3_capil."Ver",
    stg_c3_capil."Code",
    stg_c3_capil."Utang",
    stg_c3_capil."Jur_S1",
    stg_c3_capil."Jur_S2",
    stg_c3_capil."Jur_S3",
    stg_c3_capil."Mentor",
    stg_c3_capil."Piutang",
    stg_c3_capil."Univ_S1",
    stg_c3_capil."Univ_S2",
    stg_c3_capil."Univ_S3",
    stg_c3_capil."Tabungan",
    stg_c3_capil."Th_Lahir",
    stg_c3_capil."Bln_Lahir",
    stg_c3_capil."Jur_D1_D4",
    stg_c3_capil."Pesantren",
    stg_c3_capil."Tgl_Lahir",
    stg_c3_capil."Gelar_Awal",
    stg_c3_capil."Univ_D1_D4",
    stg_c3_capil."Usia_Lahir",
    stg_c3_capil."Gelar_Akhir",
    stg_c3_capil."Status_Nikah",
    stg_c3_capil."Th_Integrasi",
    stg_c3_capil."Bln_Integrasi",
    stg_c3_capil."Tgl_Integrasi",
    stg_c3_capil."Usia_Integrasi",
    stg_c3_capil."Alamat_Provinsi",
    stg_c3_capil."Jenis_Pekerjaan",
    stg_c3_capil."Status_Tabungan",
    stg_c3_capil."Status_Aktivitas",
    stg_c3_capil."Jabatan_Pekerjaan",
    stg_c3_capil."Keahlian_Khusus_A",
    stg_c3_capil."Keahlian_Khusus_B",
    stg_c3_capil."Keahlian_Khusus_C",
    stg_c3_capil."Keahlian_Khusus_D",
    stg_c3_capil."Keahlian_Khusus_E",
    stg_c3_capil."Jenis_Pemberdayaan",
    stg_c3_capil."Status_Pemberdayaan",
    stg_c3_capil."Gaji_Rata_rata_Pekerjaan",
    stg_c3_capil."Aset_Hak_Milik_Mobil__Rp_",
    stg_c3_capil."Aset_Hak_Milik_Motor__Rp_",
    stg_c3_capil."Aset_Hak_Milik_Rumah__m2_",
    stg_c3_capil."Aset_Hak_Milik_Tanah__m2_",
    stg_c3_capil."Alamat_Negara",
    stg_c3_capil."Alamat_Kabupaten",
    stg_c3_capil."Alamat_Kecamatan",
    stg_c3_capil.kantor_id
   FROM analytics.stg_c3_capil
UNION ALL
 SELECT stg_c4_capil."K",
    stg_c4_capil."JK",
    stg_c4_capil."SD",
    stg_c4_capil."LMG",
    stg_c4_capil."SMA",
    stg_c4_capil."SMP",
    stg_c4_capil."Ver",
    stg_c4_capil."Code",
    stg_c4_capil."Utang",
    stg_c4_capil."Jur_S1",
    stg_c4_capil."Jur_S2",
    stg_c4_capil."Jur_S3",
    stg_c4_capil."Mentor",
    stg_c4_capil."Piutang",
    stg_c4_capil."Univ_S1",
    stg_c4_capil."Univ_S2",
    stg_c4_capil."Univ_S3",
    stg_c4_capil."Tabungan",
    stg_c4_capil."Th_Lahir",
    stg_c4_capil."Bln_Lahir",
    stg_c4_capil."Jur_D1_D4",
    stg_c4_capil."Pesantren",
    stg_c4_capil."Tgl_Lahir",
    stg_c4_capil."Gelar_Awal",
    stg_c4_capil."Univ_D1_D4",
    stg_c4_capil."Usia_Lahir",
    stg_c4_capil."Gelar_Akhir",
    stg_c4_capil."Status_Nikah",
    stg_c4_capil."Th_Integrasi",
    stg_c4_capil."Bln_Integrasi",
    stg_c4_capil."Tgl_Integrasi",
    stg_c4_capil."Usia_Integrasi",
    stg_c4_capil."Alamat_Provinsi",
    stg_c4_capil."Jenis_Pekerjaan",
    stg_c4_capil."Status_Tabungan",
    stg_c4_capil."Status_Aktivitas",
    stg_c4_capil."Jabatan_Pekerjaan",
    stg_c4_capil."Keahlian_Khusus_A",
    stg_c4_capil."Keahlian_Khusus_B",
    stg_c4_capil."Keahlian_Khusus_C",
    stg_c4_capil."Keahlian_Khusus_D",
    stg_c4_capil."Keahlian_Khusus_E",
    stg_c4_capil."Jenis_Pemberdayaan",
    stg_c4_capil."Status_Pemberdayaan",
    stg_c4_capil."Gaji_Rata_rata_Pekerjaan",
    stg_c4_capil."Aset_Hak_Milik_Mobil__Rp_",
    stg_c4_capil."Aset_Hak_Milik_Motor__Rp_",
    stg_c4_capil."Aset_Hak_Milik_Rumah__m2_",
    stg_c4_capil."Aset_Hak_Milik_Tanah__m2_",
    stg_c4_capil."Alamat_Negara",
    stg_c4_capil."Alamat_Kabupaten",
    stg_c4_capil."Alamat_Kecamatan",
    stg_c4_capil.kantor_id
   FROM analytics.stg_c4_capil
UNION ALL
 SELECT stg_c5_capil."K",
    stg_c5_capil."JK",
    stg_c5_capil."SD",
    stg_c5_capil."LMG",
    stg_c5_capil."SMA",
    stg_c5_capil."SMP",
    stg_c5_capil."Ver",
    stg_c5_capil."Code",
    stg_c5_capil."Utang",
    stg_c5_capil."Jur_S1",
    stg_c5_capil."Jur_S2",
    stg_c5_capil."Jur_S3",
    stg_c5_capil."Mentor",
    stg_c5_capil."Piutang",
    stg_c5_capil."Univ_S1",
    stg_c5_capil."Univ_S2",
    stg_c5_capil."Univ_S3",
    stg_c5_capil."Tabungan",
    stg_c5_capil."Th_Lahir",
    stg_c5_capil."Bln_Lahir",
    stg_c5_capil."Jur_D1_D4",
    stg_c5_capil."Pesantren",
    stg_c5_capil."Tgl_Lahir",
    stg_c5_capil."Gelar_Awal",
    stg_c5_capil."Univ_D1_D4",
    stg_c5_capil."Usia_Lahir",
    stg_c5_capil."Gelar_Akhir",
    stg_c5_capil."Status_Nikah",
    stg_c5_capil."Th_Integrasi",
    stg_c5_capil."Bln_Integrasi",
    stg_c5_capil."Tgl_Integrasi",
    stg_c5_capil."Usia_Integrasi",
    stg_c5_capil."Alamat_Provinsi",
    stg_c5_capil."Jenis_Pekerjaan",
    stg_c5_capil."Status_Tabungan",
    stg_c5_capil."Status_Aktivitas",
    stg_c5_capil."Jabatan_Pekerjaan",
    stg_c5_capil."Keahlian_Khusus_A",
    stg_c5_capil."Keahlian_Khusus_B",
    stg_c5_capil."Keahlian_Khusus_C",
    stg_c5_capil."Keahlian_Khusus_D",
    stg_c5_capil."Keahlian_Khusus_E",
    stg_c5_capil."Jenis_Pemberdayaan",
    stg_c5_capil."Status_Pemberdayaan",
    stg_c5_capil."Gaji_Rata_rata_Pekerjaan",
    stg_c5_capil."Aset_Hak_Milik_Mobil__Rp_",
    stg_c5_capil."Aset_Hak_Milik_Motor__Rp_",
    stg_c5_capil."Aset_Hak_Milik_Rumah__m2_",
    stg_c5_capil."Aset_Hak_Milik_Tanah__m2_",
    stg_c5_capil."Alamat_Negara",
    stg_c5_capil."Alamat_Kabupaten",
    stg_c5_capil."Alamat_Kecamatan",
    stg_c5_capil.kantor_id
   FROM analytics.stg_c5_capil
UNION ALL
 SELECT stg_c6_capil."K",
    stg_c6_capil."JK",
    stg_c6_capil."SD",
    stg_c6_capil."LMG",
    stg_c6_capil."SMA",
    stg_c6_capil."SMP",
    stg_c6_capil."Ver",
    stg_c6_capil."Code",
    stg_c6_capil."Utang",
    stg_c6_capil."Jur_S1",
    stg_c6_capil."Jur_S2",
    stg_c6_capil."Jur_S3",
    stg_c6_capil."Mentor",
    stg_c6_capil."Piutang",
    stg_c6_capil."Univ_S1",
    stg_c6_capil."Univ_S2",
    stg_c6_capil."Univ_S3",
    stg_c6_capil."Tabungan",
    stg_c6_capil."Th_Lahir",
    stg_c6_capil."Bln_Lahir",
    stg_c6_capil."Jur_D1_D4",
    stg_c6_capil."Pesantren",
    stg_c6_capil."Tgl_Lahir",
    stg_c6_capil."Gelar_Awal",
    stg_c6_capil."Univ_D1_D4",
    stg_c6_capil."Usia_Lahir",
    stg_c6_capil."Gelar_Akhir",
    stg_c6_capil."Status_Nikah",
    stg_c6_capil."Th_Integrasi",
    stg_c6_capil."Bln_Integrasi",
    stg_c6_capil."Tgl_Integrasi",
    stg_c6_capil."Usia_Integrasi",
    stg_c6_capil."Alamat_Provinsi",
    stg_c6_capil."Jenis_Pekerjaan",
    stg_c6_capil."Status_Tabungan",
    stg_c6_capil."Status_Aktivitas",
    stg_c6_capil."Jabatan_Pekerjaan",
    stg_c6_capil."Keahlian_Khusus_A",
    stg_c6_capil."Keahlian_Khusus_B",
    stg_c6_capil."Keahlian_Khusus_C",
    stg_c6_capil."Keahlian_Khusus_D",
    stg_c6_capil."Keahlian_Khusus_E",
    stg_c6_capil."Jenis_Pemberdayaan",
    stg_c6_capil."Status_Pemberdayaan",
    stg_c6_capil."Gaji_Rata_rata_Pekerjaan",
    stg_c6_capil."Aset_Hak_Milik_Mobil__Rp_",
    stg_c6_capil."Aset_Hak_Milik_Motor__Rp_",
    stg_c6_capil."Aset_Hak_Milik_Rumah__m2_",
    stg_c6_capil."Aset_Hak_Milik_Tanah__m2_",
    stg_c6_capil."Alamat_Negara",
    stg_c6_capil."Alamat_Kabupaten",
    stg_c6_capil."Alamat_Kecamatan",
    stg_c6_capil.kantor_id
   FROM analytics.stg_c6_capil;


ALTER VIEW analytics.mart_capil OWNER TO admin;

--
-- TOC entry 266 (class 1259 OID 299269)
-- Name: raw_finance_rekap_a1; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rekap_a1 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "DISETOR" numeric,
    "DIKELOLA_KANWIL" numeric,
    "PEMBULATAN_SETOR" numeric,
    "TOTAL_100_PERSEN" numeric,
    "JENIS" character varying
);


ALTER TABLE public.raw_finance_rekap_a1 OWNER TO admin;

--
-- TOC entry 297 (class 1259 OID 329230)
-- Name: stg_a1_finance_rekap; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_a1_finance_rekap AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rekap_a1._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rekap_a1
        )
 SELECT 'A1'::text AS kantor_id,
    r."JENIS" AS jenis,
    r."DISETOR" AS disetor,
    r."DIKELOLA_KANWIL" AS dikelola_kanwil,
    r."PEMBULATAN_SETOR" AS pembulatan_setor,
    r."TOTAL_100_PERSEN" AS total_100_persen
   FROM (public.raw_finance_rekap_a1 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)));


ALTER VIEW analytics.stg_a1_finance_rekap OWNER TO admin;

--
-- TOC entry 268 (class 1259 OID 299361)
-- Name: raw_finance_rekap_a2; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rekap_a2 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "DISETOR" numeric,
    "DIKELOLA_KANWIL" numeric,
    "PEMBULATAN_SETOR" numeric,
    "TOTAL_100_PERSEN" numeric,
    "JENIS" character varying
);


ALTER TABLE public.raw_finance_rekap_a2 OWNER TO admin;

--
-- TOC entry 301 (class 1259 OID 329248)
-- Name: stg_a2_finance_rekap; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_a2_finance_rekap AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rekap_a2._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rekap_a2
        )
 SELECT 'A2'::text AS kantor_id,
    r."JENIS" AS jenis,
    r."DISETOR" AS disetor,
    r."DIKELOLA_KANWIL" AS dikelola_kanwil,
    r."PEMBULATAN_SETOR" AS pembulatan_setor,
    r."TOTAL_100_PERSEN" AS total_100_persen
   FROM (public.raw_finance_rekap_a2 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)));


ALTER VIEW analytics.stg_a2_finance_rekap OWNER TO admin;

--
-- TOC entry 270 (class 1259 OID 299391)
-- Name: raw_finance_rekap_a3; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rekap_a3 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "DISETOR" numeric,
    "DIKELOLA_KANWIL" numeric,
    "PEMBULATAN_SETOR" numeric,
    "TOTAL_100_PERSEN" numeric,
    "JENIS" character varying
);


ALTER TABLE public.raw_finance_rekap_a3 OWNER TO admin;

--
-- TOC entry 299 (class 1259 OID 329242)
-- Name: stg_a3_finance_rekap; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_a3_finance_rekap AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rekap_a3._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rekap_a3
        )
 SELECT 'A3'::text AS kantor_id,
    r."JENIS" AS jenis,
    r."DISETOR" AS disetor,
    r."DIKELOLA_KANWIL" AS dikelola_kanwil,
    r."PEMBULATAN_SETOR" AS pembulatan_setor,
    r."TOTAL_100_PERSEN" AS total_100_persen
   FROM (public.raw_finance_rekap_a3 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)));


ALTER VIEW analytics.stg_a3_finance_rekap OWNER TO admin;

--
-- TOC entry 272 (class 1259 OID 299485)
-- Name: raw_finance_rekap_b1; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rekap_b1 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "DISETOR" numeric,
    "DIKELOLA_KANWIL" numeric,
    "PEMBULATAN_SETOR" numeric,
    "TOTAL_100_PERSEN" numeric,
    "JENIS" character varying
);


ALTER TABLE public.raw_finance_rekap_b1 OWNER TO admin;

--
-- TOC entry 304 (class 1259 OID 329267)
-- Name: stg_b1_finance_rekap; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_b1_finance_rekap AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rekap_b1._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rekap_b1
        )
 SELECT 'B1'::text AS kantor_id,
    r."JENIS" AS jenis,
    r."DISETOR" AS disetor,
    r."DIKELOLA_KANWIL" AS dikelola_kanwil,
    r."PEMBULATAN_SETOR" AS pembulatan_setor,
    r."TOTAL_100_PERSEN" AS total_100_persen
   FROM (public.raw_finance_rekap_b1 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)));


ALTER VIEW analytics.stg_b1_finance_rekap OWNER TO admin;

--
-- TOC entry 274 (class 1259 OID 299510)
-- Name: raw_finance_rekap_b2; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rekap_b2 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "DISETOR" numeric,
    "DIKELOLA_KANWIL" numeric,
    "PEMBULATAN_SETOR" numeric,
    "TOTAL_100_PERSEN" numeric,
    "JENIS" character varying
);


ALTER TABLE public.raw_finance_rekap_b2 OWNER TO admin;

--
-- TOC entry 308 (class 1259 OID 329287)
-- Name: stg_b2_finance_rekap; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_b2_finance_rekap AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rekap_b2._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rekap_b2
        )
 SELECT 'B2'::text AS kantor_id,
    r."JENIS" AS jenis,
    r."DISETOR" AS disetor,
    r."DIKELOLA_KANWIL" AS dikelola_kanwil,
    r."PEMBULATAN_SETOR" AS pembulatan_setor,
    r."TOTAL_100_PERSEN" AS total_100_persen
   FROM (public.raw_finance_rekap_b2 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)));


ALTER VIEW analytics.stg_b2_finance_rekap OWNER TO admin;

--
-- TOC entry 276 (class 1259 OID 299534)
-- Name: raw_finance_rekap_b3; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rekap_b3 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "DISETOR" numeric,
    "DIKELOLA_KANWIL" numeric,
    "PEMBULATAN_SETOR" numeric,
    "TOTAL_100_PERSEN" numeric,
    "JENIS" character varying
);


ALTER TABLE public.raw_finance_rekap_b3 OWNER TO admin;

--
-- TOC entry 311 (class 1259 OID 329302)
-- Name: stg_b3_finance_rekap; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_b3_finance_rekap AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rekap_b3._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rekap_b3
        )
 SELECT 'B3'::text AS kantor_id,
    r."JENIS" AS jenis,
    r."DISETOR" AS disetor,
    r."DIKELOLA_KANWIL" AS dikelola_kanwil,
    r."PEMBULATAN_SETOR" AS pembulatan_setor,
    r."TOTAL_100_PERSEN" AS total_100_persen
   FROM (public.raw_finance_rekap_b3 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)));


ALTER VIEW analytics.stg_b3_finance_rekap OWNER TO admin;

--
-- TOC entry 278 (class 1259 OID 299558)
-- Name: raw_finance_rekap_b4; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rekap_b4 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "DISETOR" numeric,
    "DIKELOLA_KANWIL" numeric,
    "PEMBULATAN_SETOR" numeric,
    "TOTAL_100_PERSEN" numeric,
    "JENIS" character varying
);


ALTER TABLE public.raw_finance_rekap_b4 OWNER TO admin;

--
-- TOC entry 313 (class 1259 OID 329312)
-- Name: stg_b4_finance_rekap; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_b4_finance_rekap AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rekap_b4._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rekap_b4
        )
 SELECT 'B4'::text AS kantor_id,
    r."JENIS" AS jenis,
    r."DISETOR" AS disetor,
    r."DIKELOLA_KANWIL" AS dikelola_kanwil,
    r."PEMBULATAN_SETOR" AS pembulatan_setor,
    r."TOTAL_100_PERSEN" AS total_100_persen
   FROM (public.raw_finance_rekap_b4 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)));


ALTER VIEW analytics.stg_b4_finance_rekap OWNER TO admin;

--
-- TOC entry 280 (class 1259 OID 299583)
-- Name: raw_finance_rekap_b5; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rekap_b5 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "DISETOR" numeric,
    "DIKELOLA_KANWIL" numeric,
    "PEMBULATAN_SETOR" numeric,
    "TOTAL_100_PERSEN" numeric,
    "JENIS" character varying
);


ALTER TABLE public.raw_finance_rekap_b5 OWNER TO admin;

--
-- TOC entry 317 (class 1259 OID 329332)
-- Name: stg_b5_finance_rekap; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_b5_finance_rekap AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rekap_b5._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rekap_b5
        )
 SELECT 'B5'::text AS kantor_id,
    r."JENIS" AS jenis,
    r."DISETOR" AS disetor,
    r."DIKELOLA_KANWIL" AS dikelola_kanwil,
    r."PEMBULATAN_SETOR" AS pembulatan_setor,
    r."TOTAL_100_PERSEN" AS total_100_persen
   FROM (public.raw_finance_rekap_b5 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)));


ALTER VIEW analytics.stg_b5_finance_rekap OWNER TO admin;

--
-- TOC entry 281 (class 1259 OID 299604)
-- Name: raw_finance_rekap_c1; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rekap_c1 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "JENIS" character varying,
    "DISETOR" numeric,
    "DIKELOLA_KANWIL" numeric,
    "PEMBULATAN_SETOR" numeric,
    "TOTAL_100_PERSEN" numeric
);


ALTER TABLE public.raw_finance_rekap_c1 OWNER TO admin;

--
-- TOC entry 320 (class 1259 OID 329347)
-- Name: stg_c1_finance_rekap; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_c1_finance_rekap AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rekap_c1._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rekap_c1
        )
 SELECT 'C1'::text AS kantor_id,
    r."JENIS" AS jenis,
    r."DISETOR" AS disetor,
    r."DIKELOLA_KANWIL" AS dikelola_kanwil,
    r."PEMBULATAN_SETOR" AS pembulatan_setor,
    r."TOTAL_100_PERSEN" AS total_100_persen
   FROM (public.raw_finance_rekap_c1 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)));


ALTER VIEW analytics.stg_c1_finance_rekap OWNER TO admin;

--
-- TOC entry 291 (class 1259 OID 299847)
-- Name: raw_finance_rekap_c2; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rekap_c2 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "DISETOR" numeric,
    "DIKELOLA_KANWIL" numeric,
    "PEMBULATAN_SETOR" numeric,
    "TOTAL_100_PERSEN" numeric,
    "JENIS" character varying
);


ALTER TABLE public.raw_finance_rekap_c2 OWNER TO admin;

--
-- TOC entry 322 (class 1259 OID 329357)
-- Name: stg_c2_finance_rekap; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_c2_finance_rekap AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rekap_c2._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rekap_c2
        )
 SELECT 'C2'::text AS kantor_id,
    r."JENIS" AS jenis,
    r."DISETOR" AS disetor,
    r."DIKELOLA_KANWIL" AS dikelola_kanwil,
    r."PEMBULATAN_SETOR" AS pembulatan_setor,
    r."TOTAL_100_PERSEN" AS total_100_persen
   FROM (public.raw_finance_rekap_c2 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)));


ALTER VIEW analytics.stg_c2_finance_rekap OWNER TO admin;

--
-- TOC entry 284 (class 1259 OID 299739)
-- Name: raw_finance_rekap_c3; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rekap_c3 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "JENIS" character varying,
    "DISETOR" numeric,
    "DIKELOLA_KANWIL" numeric,
    "PEMBULATAN_SETOR" numeric,
    "TOTAL_100_PERSEN" numeric
);


ALTER TABLE public.raw_finance_rekap_c3 OWNER TO admin;

--
-- TOC entry 326 (class 1259 OID 329377)
-- Name: stg_c3_finance_rekap; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_c3_finance_rekap AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rekap_c3._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rekap_c3
        )
 SELECT 'C3'::text AS kantor_id,
    r."JENIS" AS jenis,
    r."DISETOR" AS disetor,
    r."DIKELOLA_KANWIL" AS dikelola_kanwil,
    r."PEMBULATAN_SETOR" AS pembulatan_setor,
    r."TOTAL_100_PERSEN" AS total_100_persen
   FROM (public.raw_finance_rekap_c3 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)));


ALTER VIEW analytics.stg_c3_finance_rekap OWNER TO admin;

--
-- TOC entry 286 (class 1259 OID 299763)
-- Name: raw_finance_rekap_c4; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rekap_c4 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "DISETOR" numeric,
    "DIKELOLA_KANWIL" numeric,
    "PEMBULATAN_SETOR" numeric,
    "TOTAL_100_PERSEN" numeric,
    "JENIS" character varying
);


ALTER TABLE public.raw_finance_rekap_c4 OWNER TO admin;

--
-- TOC entry 329 (class 1259 OID 329392)
-- Name: stg_c4_finance_rekap; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_c4_finance_rekap AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rekap_c4._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rekap_c4
        )
 SELECT 'C4'::text AS kantor_id,
    r."JENIS" AS jenis,
    r."DISETOR" AS disetor,
    r."DIKELOLA_KANWIL" AS dikelola_kanwil,
    r."PEMBULATAN_SETOR" AS pembulatan_setor,
    r."TOTAL_100_PERSEN" AS total_100_persen
   FROM (public.raw_finance_rekap_c4 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)));


ALTER VIEW analytics.stg_c4_finance_rekap OWNER TO admin;

--
-- TOC entry 335 (class 1259 OID 329422)
-- Name: mart_finance_rekap; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.mart_finance_rekap AS
 SELECT stg_a1_finance_rekap.kantor_id,
    stg_a1_finance_rekap.jenis,
    stg_a1_finance_rekap.disetor,
    stg_a1_finance_rekap.dikelola_kanwil,
    stg_a1_finance_rekap.pembulatan_setor,
    stg_a1_finance_rekap.total_100_persen
   FROM analytics.stg_a1_finance_rekap
UNION ALL
 SELECT stg_a2_finance_rekap.kantor_id,
    stg_a2_finance_rekap.jenis,
    stg_a2_finance_rekap.disetor,
    stg_a2_finance_rekap.dikelola_kanwil,
    stg_a2_finance_rekap.pembulatan_setor,
    stg_a2_finance_rekap.total_100_persen
   FROM analytics.stg_a2_finance_rekap
UNION ALL
 SELECT stg_a3_finance_rekap.kantor_id,
    stg_a3_finance_rekap.jenis,
    stg_a3_finance_rekap.disetor,
    stg_a3_finance_rekap.dikelola_kanwil,
    stg_a3_finance_rekap.pembulatan_setor,
    stg_a3_finance_rekap.total_100_persen
   FROM analytics.stg_a3_finance_rekap
UNION ALL
 SELECT stg_b1_finance_rekap.kantor_id,
    stg_b1_finance_rekap.jenis,
    stg_b1_finance_rekap.disetor,
    stg_b1_finance_rekap.dikelola_kanwil,
    stg_b1_finance_rekap.pembulatan_setor,
    stg_b1_finance_rekap.total_100_persen
   FROM analytics.stg_b1_finance_rekap
UNION ALL
 SELECT stg_b2_finance_rekap.kantor_id,
    stg_b2_finance_rekap.jenis,
    stg_b2_finance_rekap.disetor,
    stg_b2_finance_rekap.dikelola_kanwil,
    stg_b2_finance_rekap.pembulatan_setor,
    stg_b2_finance_rekap.total_100_persen
   FROM analytics.stg_b2_finance_rekap
UNION ALL
 SELECT stg_b3_finance_rekap.kantor_id,
    stg_b3_finance_rekap.jenis,
    stg_b3_finance_rekap.disetor,
    stg_b3_finance_rekap.dikelola_kanwil,
    stg_b3_finance_rekap.pembulatan_setor,
    stg_b3_finance_rekap.total_100_persen
   FROM analytics.stg_b3_finance_rekap
UNION ALL
 SELECT stg_b4_finance_rekap.kantor_id,
    stg_b4_finance_rekap.jenis,
    stg_b4_finance_rekap.disetor,
    stg_b4_finance_rekap.dikelola_kanwil,
    stg_b4_finance_rekap.pembulatan_setor,
    stg_b4_finance_rekap.total_100_persen
   FROM analytics.stg_b4_finance_rekap
UNION ALL
 SELECT stg_b5_finance_rekap.kantor_id,
    stg_b5_finance_rekap.jenis,
    stg_b5_finance_rekap.disetor,
    stg_b5_finance_rekap.dikelola_kanwil,
    stg_b5_finance_rekap.pembulatan_setor,
    stg_b5_finance_rekap.total_100_persen
   FROM analytics.stg_b5_finance_rekap
UNION ALL
 SELECT stg_c1_finance_rekap.kantor_id,
    stg_c1_finance_rekap.jenis,
    stg_c1_finance_rekap.disetor,
    stg_c1_finance_rekap.dikelola_kanwil,
    stg_c1_finance_rekap.pembulatan_setor,
    stg_c1_finance_rekap.total_100_persen
   FROM analytics.stg_c1_finance_rekap
UNION ALL
 SELECT stg_c2_finance_rekap.kantor_id,
    stg_c2_finance_rekap.jenis,
    stg_c2_finance_rekap.disetor,
    stg_c2_finance_rekap.dikelola_kanwil,
    stg_c2_finance_rekap.pembulatan_setor,
    stg_c2_finance_rekap.total_100_persen
   FROM analytics.stg_c2_finance_rekap
UNION ALL
 SELECT stg_c3_finance_rekap.kantor_id,
    stg_c3_finance_rekap.jenis,
    stg_c3_finance_rekap.disetor,
    stg_c3_finance_rekap.dikelola_kanwil,
    stg_c3_finance_rekap.pembulatan_setor,
    stg_c3_finance_rekap.total_100_persen
   FROM analytics.stg_c3_finance_rekap
UNION ALL
 SELECT stg_c4_finance_rekap.kantor_id,
    stg_c4_finance_rekap.jenis,
    stg_c4_finance_rekap.disetor,
    stg_c4_finance_rekap.dikelola_kanwil,
    stg_c4_finance_rekap.pembulatan_setor,
    stg_c4_finance_rekap.total_100_persen
   FROM analytics.stg_c4_finance_rekap;


ALTER VIEW analytics.mart_finance_rekap OWNER TO admin;

--
-- TOC entry 265 (class 1259 OID 299111)
-- Name: raw_finance_rincian_a1; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rincian_a1 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "INSTANSI" character varying,
    "TUNAI_FI" numeric,
    "TUNAI_ZF" numeric,
    "TUNAI_AQQ" numeric,
    "TUNAI_FDY" numeric,
    "TUNAI_IFQ" numeric,
    "TUNAI_LQT" numeric,
    "TUNAI_SDQ" numeric,
    "TUNAI_SNK" numeric,
    "TUNAI_TDY" numeric,
    "TUNAI_ZKT" numeric,
    "NOMINAL_FI" numeric,
    "NOMINAL_ZF" numeric,
    "NOMINAL_AQQ" numeric,
    "NOMINAL_FDY" numeric,
    "NOMINAL_IFQ" numeric,
    "NOMINAL_LQT" numeric,
    "NOMINAL_SDQ" numeric,
    "NOMINAL_SNK" numeric,
    "NOMINAL_TDY" numeric,
    "NOMINAL_ZKT" numeric
);


ALTER TABLE public.raw_finance_rincian_a1 OWNER TO admin;

--
-- TOC entry 298 (class 1259 OID 329233)
-- Name: stg_a1_finance_rincian; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_a1_finance_rincian AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rincian_a1._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rincian_a1
        ), wajib_ifq_calc AS (
         SELECT c."LMG" AS instansi,
            count(*) AS wajib_ifq
           FROM (public.raw_a1 c
             JOIN ( SELECT max(raw_a1._airbyte_generation_id) AS last_generation_id
                   FROM public.raw_a1) cg ON ((c._airbyte_generation_id = cg.last_generation_id)))
          WHERE ((c."Status_Tabungan")::text = 'Paham'::text)
          GROUP BY c."LMG"
        )
 SELECT 'A1'::text AS kantor_id,
    r."INSTANSI" AS instansi,
    (COALESCE(w.wajib_ifq, (0)::bigint))::numeric AS wajib_ifq,
    r."TUNAI_FI" AS tunai_fi,
    r."TUNAI_ZF" AS tunai_zf,
    r."TUNAI_AQQ" AS tunai_aqq,
    r."TUNAI_FDY" AS tunai_fdy,
    r."TUNAI_IFQ" AS tunai_ifq,
    r."TUNAI_LQT" AS tunai_lqt,
    r."TUNAI_SDQ" AS tunai_sdq,
    r."TUNAI_SNK" AS tunai_snk,
    r."TUNAI_TDY" AS tunai_tdy,
    r."TUNAI_ZKT" AS tunai_zkt,
    r."NOMINAL_FI" AS nominal_fi,
    r."NOMINAL_ZF" AS nominal_zf,
    r."NOMINAL_AQQ" AS nominal_aqq,
    r."NOMINAL_FDY" AS nominal_fdy,
    r."NOMINAL_IFQ" AS nominal_ifq,
    r."NOMINAL_LQT" AS nominal_lqt,
    r."NOMINAL_SDQ" AS nominal_sdq,
    r."NOMINAL_SNK" AS nominal_snk,
    r."NOMINAL_TDY" AS nominal_tdy,
    r."NOMINAL_ZKT" AS nominal_zkt
   FROM ((public.raw_finance_rincian_a1 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
     LEFT JOIN wajib_ifq_calc w ON (((w.instansi)::text = (r."INSTANSI")::text)));


ALTER VIEW analytics.stg_a1_finance_rincian OWNER TO admin;

--
-- TOC entry 267 (class 1259 OID 299282)
-- Name: raw_finance_rincian_a2; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rincian_a2 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "INSTANSI" character varying,
    "TUNAI_FI" numeric,
    "TUNAI_ZF" numeric,
    "TUNAI_AQQ" numeric,
    "TUNAI_FDY" numeric,
    "TUNAI_IFQ" numeric,
    "TUNAI_LQT" numeric,
    "TUNAI_SDQ" numeric,
    "TUNAI_SNK" numeric,
    "TUNAI_TDY" numeric,
    "TUNAI_ZKT" numeric,
    "NOMINAL_FI" numeric,
    "NOMINAL_ZF" numeric,
    "NOMINAL_AQQ" numeric,
    "NOMINAL_FDY" numeric,
    "NOMINAL_IFQ" numeric,
    "NOMINAL_LQT" numeric,
    "NOMINAL_SDQ" numeric,
    "NOMINAL_SNK" numeric,
    "NOMINAL_TDY" numeric,
    "NOMINAL_ZKT" numeric
);


ALTER TABLE public.raw_finance_rincian_a2 OWNER TO admin;

--
-- TOC entry 302 (class 1259 OID 329257)
-- Name: stg_a2_finance_rincian; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_a2_finance_rincian AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rincian_a2._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rincian_a2
        ), wajib_ifq_calc AS (
         SELECT c."LMG" AS instansi,
            count(*) AS wajib_ifq
           FROM (public.raw_a2 c
             JOIN ( SELECT max(raw_a2._airbyte_generation_id) AS last_generation_id
                   FROM public.raw_a2) cg ON ((c._airbyte_generation_id = cg.last_generation_id)))
          WHERE ((c."Status_Tabungan")::text = 'Paham'::text)
          GROUP BY c."LMG"
        )
 SELECT 'A2'::text AS kantor_id,
    r."INSTANSI" AS instansi,
    (COALESCE(w.wajib_ifq, (0)::bigint))::numeric AS wajib_ifq,
    r."TUNAI_FI" AS tunai_fi,
    r."TUNAI_ZF" AS tunai_zf,
    r."TUNAI_AQQ" AS tunai_aqq,
    r."TUNAI_FDY" AS tunai_fdy,
    r."TUNAI_IFQ" AS tunai_ifq,
    r."TUNAI_LQT" AS tunai_lqt,
    r."TUNAI_SDQ" AS tunai_sdq,
    r."TUNAI_SNK" AS tunai_snk,
    r."TUNAI_TDY" AS tunai_tdy,
    r."TUNAI_ZKT" AS tunai_zkt,
    r."NOMINAL_FI" AS nominal_fi,
    r."NOMINAL_ZF" AS nominal_zf,
    r."NOMINAL_AQQ" AS nominal_aqq,
    r."NOMINAL_FDY" AS nominal_fdy,
    r."NOMINAL_IFQ" AS nominal_ifq,
    r."NOMINAL_LQT" AS nominal_lqt,
    r."NOMINAL_SDQ" AS nominal_sdq,
    r."NOMINAL_SNK" AS nominal_snk,
    r."NOMINAL_TDY" AS nominal_tdy,
    r."NOMINAL_ZKT" AS nominal_zkt
   FROM ((public.raw_finance_rincian_a2 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
     LEFT JOIN wajib_ifq_calc w ON (((w.instansi)::text = (r."INSTANSI")::text)));


ALTER VIEW analytics.stg_a2_finance_rincian OWNER TO admin;

--
-- TOC entry 269 (class 1259 OID 299373)
-- Name: raw_finance_rincian_a3; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rincian_a3 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "INSTANSI" character varying,
    "TUNAI_FI" numeric,
    "TUNAI_ZF" numeric,
    "TUNAI_AQQ" numeric,
    "TUNAI_FDY" numeric,
    "TUNAI_IFQ" numeric,
    "TUNAI_LQT" numeric,
    "TUNAI_SDQ" numeric,
    "TUNAI_SNK" numeric,
    "TUNAI_TDY" numeric,
    "TUNAI_ZKT" numeric,
    "NOMINAL_FI" numeric,
    "NOMINAL_ZF" numeric,
    "NOMINAL_AQQ" numeric,
    "NOMINAL_FDY" numeric,
    "NOMINAL_IFQ" numeric,
    "NOMINAL_LQT" numeric,
    "NOMINAL_SDQ" numeric,
    "NOMINAL_SNK" numeric,
    "NOMINAL_TDY" numeric,
    "NOMINAL_ZKT" numeric
);


ALTER TABLE public.raw_finance_rincian_a3 OWNER TO admin;

--
-- TOC entry 303 (class 1259 OID 329262)
-- Name: stg_a3_finance_rincian; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_a3_finance_rincian AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rincian_a3._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rincian_a3
        ), wajib_ifq_calc AS (
         SELECT c."LMG" AS instansi,
            count(*) AS wajib_ifq
           FROM (public.raw_a3 c
             JOIN ( SELECT max(raw_a3._airbyte_generation_id) AS last_generation_id
                   FROM public.raw_a3) cg ON ((c._airbyte_generation_id = cg.last_generation_id)))
          WHERE ((c."Status_Tabungan")::text = 'Paham'::text)
          GROUP BY c."LMG"
        )
 SELECT 'A3'::text AS kantor_id,
    r."INSTANSI" AS instansi,
    (COALESCE(w.wajib_ifq, (0)::bigint))::numeric AS wajib_ifq,
    r."TUNAI_FI" AS tunai_fi,
    r."TUNAI_ZF" AS tunai_zf,
    r."TUNAI_AQQ" AS tunai_aqq,
    r."TUNAI_FDY" AS tunai_fdy,
    r."TUNAI_IFQ" AS tunai_ifq,
    r."TUNAI_LQT" AS tunai_lqt,
    r."TUNAI_SDQ" AS tunai_sdq,
    r."TUNAI_SNK" AS tunai_snk,
    r."TUNAI_TDY" AS tunai_tdy,
    r."TUNAI_ZKT" AS tunai_zkt,
    r."NOMINAL_FI" AS nominal_fi,
    r."NOMINAL_ZF" AS nominal_zf,
    r."NOMINAL_AQQ" AS nominal_aqq,
    r."NOMINAL_FDY" AS nominal_fdy,
    r."NOMINAL_IFQ" AS nominal_ifq,
    r."NOMINAL_LQT" AS nominal_lqt,
    r."NOMINAL_SDQ" AS nominal_sdq,
    r."NOMINAL_SNK" AS nominal_snk,
    r."NOMINAL_TDY" AS nominal_tdy,
    r."NOMINAL_ZKT" AS nominal_zkt
   FROM ((public.raw_finance_rincian_a3 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
     LEFT JOIN wajib_ifq_calc w ON (((w.instansi)::text = (r."INSTANSI")::text)));


ALTER VIEW analytics.stg_a3_finance_rincian OWNER TO admin;

--
-- TOC entry 271 (class 1259 OID 299473)
-- Name: raw_finance_rincian_b1; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rincian_b1 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "INSTANSI" character varying,
    "TUNAI_FI" numeric,
    "TUNAI_ZF" numeric,
    "TUNAI_AQQ" numeric,
    "TUNAI_FDY" numeric,
    "TUNAI_IFQ" numeric,
    "TUNAI_LQT" numeric,
    "TUNAI_SDQ" numeric,
    "TUNAI_SNK" numeric,
    "TUNAI_TDY" numeric,
    "TUNAI_ZKT" numeric,
    "NOMINAL_FI" numeric,
    "NOMINAL_ZF" numeric,
    "NOMINAL_AQQ" numeric,
    "NOMINAL_FDY" numeric,
    "NOMINAL_IFQ" numeric,
    "NOMINAL_LQT" numeric,
    "NOMINAL_SDQ" numeric,
    "NOMINAL_SNK" numeric,
    "NOMINAL_TDY" numeric,
    "NOMINAL_ZKT" numeric
);


ALTER TABLE public.raw_finance_rincian_b1 OWNER TO admin;

--
-- TOC entry 306 (class 1259 OID 329277)
-- Name: stg_b1_finance_rincian; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_b1_finance_rincian AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rincian_b1._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rincian_b1
        ), wajib_ifq_calc AS (
         SELECT c."LMG" AS instansi,
            count(*) AS wajib_ifq
           FROM (public.raw_b1 c
             JOIN ( SELECT max(raw_b1._airbyte_generation_id) AS last_generation_id
                   FROM public.raw_b1) cg ON ((c._airbyte_generation_id = cg.last_generation_id)))
          WHERE ((c."Status_Tabungan")::text = 'Paham'::text)
          GROUP BY c."LMG"
        )
 SELECT 'B1'::text AS kantor_id,
    r."INSTANSI" AS instansi,
    (COALESCE(w.wajib_ifq, (0)::bigint))::numeric AS wajib_ifq,
    r."TUNAI_FI" AS tunai_fi,
    r."TUNAI_ZF" AS tunai_zf,
    r."TUNAI_AQQ" AS tunai_aqq,
    r."TUNAI_FDY" AS tunai_fdy,
    r."TUNAI_IFQ" AS tunai_ifq,
    r."TUNAI_LQT" AS tunai_lqt,
    r."TUNAI_SDQ" AS tunai_sdq,
    r."TUNAI_SNK" AS tunai_snk,
    r."TUNAI_TDY" AS tunai_tdy,
    r."TUNAI_ZKT" AS tunai_zkt,
    r."NOMINAL_FI" AS nominal_fi,
    r."NOMINAL_ZF" AS nominal_zf,
    r."NOMINAL_AQQ" AS nominal_aqq,
    r."NOMINAL_FDY" AS nominal_fdy,
    r."NOMINAL_IFQ" AS nominal_ifq,
    r."NOMINAL_LQT" AS nominal_lqt,
    r."NOMINAL_SDQ" AS nominal_sdq,
    r."NOMINAL_SNK" AS nominal_snk,
    r."NOMINAL_TDY" AS nominal_tdy,
    r."NOMINAL_ZKT" AS nominal_zkt
   FROM ((public.raw_finance_rincian_b1 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
     LEFT JOIN wajib_ifq_calc w ON (((w.instansi)::text = (r."INSTANSI")::text)));


ALTER VIEW analytics.stg_b1_finance_rincian OWNER TO admin;

--
-- TOC entry 273 (class 1259 OID 299497)
-- Name: raw_finance_rincian_b2; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rincian_b2 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "INSTANSI" character varying,
    "TUNAI_FI" numeric,
    "TUNAI_ZF" numeric,
    "TUNAI_AQQ" numeric,
    "TUNAI_FDY" numeric,
    "TUNAI_IFQ" numeric,
    "TUNAI_LQT" numeric,
    "TUNAI_SDQ" numeric,
    "TUNAI_SNK" numeric,
    "TUNAI_TDY" numeric,
    "TUNAI_ZKT" numeric,
    "NOMINAL_FI" numeric,
    "NOMINAL_ZF" numeric,
    "NOMINAL_AQQ" numeric,
    "NOMINAL_FDY" numeric,
    "NOMINAL_IFQ" numeric,
    "NOMINAL_LQT" numeric,
    "NOMINAL_SDQ" numeric,
    "NOMINAL_SNK" numeric,
    "NOMINAL_TDY" numeric,
    "NOMINAL_ZKT" numeric
);


ALTER TABLE public.raw_finance_rincian_b2 OWNER TO admin;

--
-- TOC entry 310 (class 1259 OID 329295)
-- Name: stg_b2_finance_rincian; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_b2_finance_rincian AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rincian_b2._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rincian_b2
        ), wajib_ifq_calc AS (
         SELECT c."LMG" AS instansi,
            count(*) AS wajib_ifq
           FROM (public.raw_b2 c
             JOIN ( SELECT max(raw_b2._airbyte_generation_id) AS last_generation_id
                   FROM public.raw_b2) cg ON ((c._airbyte_generation_id = cg.last_generation_id)))
          WHERE ((c."Status_Tabungan")::text = 'Paham'::text)
          GROUP BY c."LMG"
        )
 SELECT 'B2'::text AS kantor_id,
    r."INSTANSI" AS instansi,
    (COALESCE(w.wajib_ifq, (0)::bigint))::numeric AS wajib_ifq,
    r."TUNAI_FI" AS tunai_fi,
    r."TUNAI_ZF" AS tunai_zf,
    r."TUNAI_AQQ" AS tunai_aqq,
    r."TUNAI_FDY" AS tunai_fdy,
    r."TUNAI_IFQ" AS tunai_ifq,
    r."TUNAI_LQT" AS tunai_lqt,
    r."TUNAI_SDQ" AS tunai_sdq,
    r."TUNAI_SNK" AS tunai_snk,
    r."TUNAI_TDY" AS tunai_tdy,
    r."TUNAI_ZKT" AS tunai_zkt,
    r."NOMINAL_FI" AS nominal_fi,
    r."NOMINAL_ZF" AS nominal_zf,
    r."NOMINAL_AQQ" AS nominal_aqq,
    r."NOMINAL_FDY" AS nominal_fdy,
    r."NOMINAL_IFQ" AS nominal_ifq,
    r."NOMINAL_LQT" AS nominal_lqt,
    r."NOMINAL_SDQ" AS nominal_sdq,
    r."NOMINAL_SNK" AS nominal_snk,
    r."NOMINAL_TDY" AS nominal_tdy,
    r."NOMINAL_ZKT" AS nominal_zkt
   FROM ((public.raw_finance_rincian_b2 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
     LEFT JOIN wajib_ifq_calc w ON (((w.instansi)::text = (r."INSTANSI")::text)));


ALTER VIEW analytics.stg_b2_finance_rincian OWNER TO admin;

--
-- TOC entry 275 (class 1259 OID 299522)
-- Name: raw_finance_rincian_b3; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rincian_b3 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "INSTANSI" character varying,
    "TUNAI_FI" numeric,
    "TUNAI_ZF" numeric,
    "TUNAI_AQQ" numeric,
    "TUNAI_FDY" numeric,
    "TUNAI_IFQ" numeric,
    "TUNAI_LQT" numeric,
    "TUNAI_SDQ" numeric,
    "TUNAI_SNK" numeric,
    "TUNAI_TDY" numeric,
    "TUNAI_ZKT" numeric,
    "NOMINAL_FI" numeric,
    "NOMINAL_ZF" numeric,
    "NOMINAL_AQQ" numeric,
    "NOMINAL_FDY" numeric,
    "NOMINAL_IFQ" numeric,
    "NOMINAL_LQT" numeric,
    "NOMINAL_SDQ" numeric,
    "NOMINAL_SNK" numeric,
    "NOMINAL_TDY" numeric,
    "NOMINAL_ZKT" numeric
);


ALTER TABLE public.raw_finance_rincian_b3 OWNER TO admin;

--
-- TOC entry 312 (class 1259 OID 329307)
-- Name: stg_b3_finance_rincian; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_b3_finance_rincian AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rincian_b3._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rincian_b3
        ), wajib_ifq_calc AS (
         SELECT c."LMG" AS instansi,
            count(*) AS wajib_ifq
           FROM (public.raw_b3 c
             JOIN ( SELECT max(raw_b3._airbyte_generation_id) AS last_generation_id
                   FROM public.raw_b3) cg ON ((c._airbyte_generation_id = cg.last_generation_id)))
          WHERE ((c."Status_Tabungan")::text = 'Paham'::text)
          GROUP BY c."LMG"
        )
 SELECT 'B3'::text AS kantor_id,
    r."INSTANSI" AS instansi,
    (COALESCE(w.wajib_ifq, (0)::bigint))::numeric AS wajib_ifq,
    r."TUNAI_FI" AS tunai_fi,
    r."TUNAI_ZF" AS tunai_zf,
    r."TUNAI_AQQ" AS tunai_aqq,
    r."TUNAI_FDY" AS tunai_fdy,
    r."TUNAI_IFQ" AS tunai_ifq,
    r."TUNAI_LQT" AS tunai_lqt,
    r."TUNAI_SDQ" AS tunai_sdq,
    r."TUNAI_SNK" AS tunai_snk,
    r."TUNAI_TDY" AS tunai_tdy,
    r."TUNAI_ZKT" AS tunai_zkt,
    r."NOMINAL_FI" AS nominal_fi,
    r."NOMINAL_ZF" AS nominal_zf,
    r."NOMINAL_AQQ" AS nominal_aqq,
    r."NOMINAL_FDY" AS nominal_fdy,
    r."NOMINAL_IFQ" AS nominal_ifq,
    r."NOMINAL_LQT" AS nominal_lqt,
    r."NOMINAL_SDQ" AS nominal_sdq,
    r."NOMINAL_SNK" AS nominal_snk,
    r."NOMINAL_TDY" AS nominal_tdy,
    r."NOMINAL_ZKT" AS nominal_zkt
   FROM ((public.raw_finance_rincian_b3 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
     LEFT JOIN wajib_ifq_calc w ON (((w.instansi)::text = (r."INSTANSI")::text)));


ALTER VIEW analytics.stg_b3_finance_rincian OWNER TO admin;

--
-- TOC entry 277 (class 1259 OID 299546)
-- Name: raw_finance_rincian_b4; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rincian_b4 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "INSTANSI" character varying,
    "TUNAI_FI" numeric,
    "TUNAI_ZF" numeric,
    "TUNAI_AQQ" numeric,
    "TUNAI_FDY" numeric,
    "TUNAI_IFQ" numeric,
    "TUNAI_LQT" numeric,
    "TUNAI_SDQ" numeric,
    "TUNAI_SNK" numeric,
    "TUNAI_TDY" numeric,
    "TUNAI_ZKT" numeric,
    "NOMINAL_FI" numeric,
    "NOMINAL_ZF" numeric,
    "NOMINAL_AQQ" numeric,
    "NOMINAL_FDY" numeric,
    "NOMINAL_IFQ" numeric,
    "NOMINAL_LQT" numeric,
    "NOMINAL_SDQ" numeric,
    "NOMINAL_SNK" numeric,
    "NOMINAL_TDY" numeric,
    "NOMINAL_ZKT" numeric
);


ALTER TABLE public.raw_finance_rincian_b4 OWNER TO admin;

--
-- TOC entry 315 (class 1259 OID 329322)
-- Name: stg_b4_finance_rincian; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_b4_finance_rincian AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rincian_b4._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rincian_b4
        ), wajib_ifq_calc AS (
         SELECT c."LMG" AS instansi,
            count(*) AS wajib_ifq
           FROM (public.raw_b4 c
             JOIN ( SELECT max(raw_b4._airbyte_generation_id) AS last_generation_id
                   FROM public.raw_b4) cg ON ((c._airbyte_generation_id = cg.last_generation_id)))
          WHERE ((c."Status_Tabungan")::text = 'Paham'::text)
          GROUP BY c."LMG"
        )
 SELECT 'B4'::text AS kantor_id,
    r."INSTANSI" AS instansi,
    (COALESCE(w.wajib_ifq, (0)::bigint))::numeric AS wajib_ifq,
    r."TUNAI_FI" AS tunai_fi,
    r."TUNAI_ZF" AS tunai_zf,
    r."TUNAI_AQQ" AS tunai_aqq,
    r."TUNAI_FDY" AS tunai_fdy,
    r."TUNAI_IFQ" AS tunai_ifq,
    r."TUNAI_LQT" AS tunai_lqt,
    r."TUNAI_SDQ" AS tunai_sdq,
    r."TUNAI_SNK" AS tunai_snk,
    r."TUNAI_TDY" AS tunai_tdy,
    r."TUNAI_ZKT" AS tunai_zkt,
    r."NOMINAL_FI" AS nominal_fi,
    r."NOMINAL_ZF" AS nominal_zf,
    r."NOMINAL_AQQ" AS nominal_aqq,
    r."NOMINAL_FDY" AS nominal_fdy,
    r."NOMINAL_IFQ" AS nominal_ifq,
    r."NOMINAL_LQT" AS nominal_lqt,
    r."NOMINAL_SDQ" AS nominal_sdq,
    r."NOMINAL_SNK" AS nominal_snk,
    r."NOMINAL_TDY" AS nominal_tdy,
    r."NOMINAL_ZKT" AS nominal_zkt
   FROM ((public.raw_finance_rincian_b4 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
     LEFT JOIN wajib_ifq_calc w ON (((w.instansi)::text = (r."INSTANSI")::text)));


ALTER VIEW analytics.stg_b4_finance_rincian OWNER TO admin;

--
-- TOC entry 279 (class 1259 OID 299571)
-- Name: raw_finance_rincian_b5; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rincian_b5 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "INSTANSI" character varying,
    "TUNAI_FI" numeric,
    "TUNAI_ZF" numeric,
    "TUNAI_AQQ" numeric,
    "TUNAI_FDY" numeric,
    "TUNAI_IFQ" numeric,
    "TUNAI_LQT" numeric,
    "TUNAI_SDQ" numeric,
    "TUNAI_SNK" numeric,
    "TUNAI_TDY" numeric,
    "TUNAI_ZKT" numeric,
    "NOMINAL_FI" numeric,
    "NOMINAL_ZF" numeric,
    "NOMINAL_AQQ" numeric,
    "NOMINAL_FDY" numeric,
    "NOMINAL_IFQ" numeric,
    "NOMINAL_LQT" numeric,
    "NOMINAL_SDQ" numeric,
    "NOMINAL_SNK" numeric,
    "NOMINAL_TDY" numeric,
    "NOMINAL_ZKT" numeric
);


ALTER TABLE public.raw_finance_rincian_b5 OWNER TO admin;

--
-- TOC entry 318 (class 1259 OID 329337)
-- Name: stg_b5_finance_rincian; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_b5_finance_rincian AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rincian_b5._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rincian_b5
        ), wajib_ifq_calc AS (
         SELECT c."LMG" AS instansi,
            count(*) AS wajib_ifq
           FROM (public.raw_b5 c
             JOIN ( SELECT max(raw_b5._airbyte_generation_id) AS last_generation_id
                   FROM public.raw_b5) cg ON ((c._airbyte_generation_id = cg.last_generation_id)))
          WHERE ((c."Status_Tabungan")::text = 'Paham'::text)
          GROUP BY c."LMG"
        )
 SELECT 'B5'::text AS kantor_id,
    r."INSTANSI" AS instansi,
    (COALESCE(w.wajib_ifq, (0)::bigint))::numeric AS wajib_ifq,
    r."TUNAI_FI" AS tunai_fi,
    r."TUNAI_ZF" AS tunai_zf,
    r."TUNAI_AQQ" AS tunai_aqq,
    r."TUNAI_FDY" AS tunai_fdy,
    r."TUNAI_IFQ" AS tunai_ifq,
    r."TUNAI_LQT" AS tunai_lqt,
    r."TUNAI_SDQ" AS tunai_sdq,
    r."TUNAI_SNK" AS tunai_snk,
    r."TUNAI_TDY" AS tunai_tdy,
    r."TUNAI_ZKT" AS tunai_zkt,
    r."NOMINAL_FI" AS nominal_fi,
    r."NOMINAL_ZF" AS nominal_zf,
    r."NOMINAL_AQQ" AS nominal_aqq,
    r."NOMINAL_FDY" AS nominal_fdy,
    r."NOMINAL_IFQ" AS nominal_ifq,
    r."NOMINAL_LQT" AS nominal_lqt,
    r."NOMINAL_SDQ" AS nominal_sdq,
    r."NOMINAL_SNK" AS nominal_snk,
    r."NOMINAL_TDY" AS nominal_tdy,
    r."NOMINAL_ZKT" AS nominal_zkt
   FROM ((public.raw_finance_rincian_b5 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
     LEFT JOIN wajib_ifq_calc w ON (((w.instansi)::text = (r."INSTANSI")::text)));


ALTER VIEW analytics.stg_b5_finance_rincian OWNER TO admin;

--
-- TOC entry 292 (class 1259 OID 299872)
-- Name: raw_finance_rincian_c1; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rincian_c1 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "INSTANSI" character varying,
    "TUNAI_FI" numeric,
    "TUNAI_ZF" numeric,
    "TUNAI_AQQ" numeric,
    "TUNAI_FDY" numeric,
    "TUNAI_IFQ" numeric,
    "TUNAI_LQT" numeric,
    "TUNAI_SDQ" numeric,
    "TUNAI_SNK" numeric,
    "TUNAI_TDY" numeric,
    "TUNAI_ZKT" numeric,
    "NOMINAL_FI" numeric,
    "NOMINAL_ZF" numeric,
    "NOMINAL_AQQ" numeric,
    "NOMINAL_FDY" numeric,
    "NOMINAL_IFQ" numeric,
    "NOMINAL_LQT" numeric,
    "NOMINAL_SDQ" numeric,
    "NOMINAL_SNK" numeric,
    "NOMINAL_TDY" numeric,
    "NOMINAL_ZKT" numeric
);


ALTER TABLE public.raw_finance_rincian_c1 OWNER TO admin;

--
-- TOC entry 323 (class 1259 OID 329362)
-- Name: stg_c1_finance_rincian; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_c1_finance_rincian AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rincian_c1._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rincian_c1
        ), wajib_ifq_calc AS (
         SELECT c."LMG" AS instansi,
            count(*) AS wajib_ifq
           FROM (public.raw_c1 c
             JOIN ( SELECT max(raw_c1._airbyte_generation_id) AS last_generation_id
                   FROM public.raw_c1) cg ON ((c._airbyte_generation_id = cg.last_generation_id)))
          WHERE ((c."Status_Tabungan")::text = 'Paham'::text)
          GROUP BY c."LMG"
        )
 SELECT 'C1'::text AS kantor_id,
    r."INSTANSI" AS instansi,
    (COALESCE(w.wajib_ifq, (0)::bigint))::numeric AS wajib_ifq,
    r."TUNAI_FI" AS tunai_fi,
    r."TUNAI_ZF" AS tunai_zf,
    r."TUNAI_AQQ" AS tunai_aqq,
    r."TUNAI_FDY" AS tunai_fdy,
    r."TUNAI_IFQ" AS tunai_ifq,
    r."TUNAI_LQT" AS tunai_lqt,
    r."TUNAI_SDQ" AS tunai_sdq,
    r."TUNAI_SNK" AS tunai_snk,
    r."TUNAI_TDY" AS tunai_tdy,
    r."TUNAI_ZKT" AS tunai_zkt,
    r."NOMINAL_FI" AS nominal_fi,
    r."NOMINAL_ZF" AS nominal_zf,
    r."NOMINAL_AQQ" AS nominal_aqq,
    r."NOMINAL_FDY" AS nominal_fdy,
    r."NOMINAL_IFQ" AS nominal_ifq,
    r."NOMINAL_LQT" AS nominal_lqt,
    r."NOMINAL_SDQ" AS nominal_sdq,
    r."NOMINAL_SNK" AS nominal_snk,
    r."NOMINAL_TDY" AS nominal_tdy,
    r."NOMINAL_ZKT" AS nominal_zkt
   FROM ((public.raw_finance_rincian_c1 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
     LEFT JOIN wajib_ifq_calc w ON (((w.instansi)::text = (r."INSTANSI")::text)));


ALTER VIEW analytics.stg_c1_finance_rincian OWNER TO admin;

--
-- TOC entry 282 (class 1259 OID 299714)
-- Name: raw_finance_rincian_c2; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rincian_c2 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "INSTANSI" character varying,
    "TUNAI_FI" numeric,
    "TUNAI_ZF" numeric,
    "TUNAI_AQQ" numeric,
    "TUNAI_FDY" numeric,
    "TUNAI_IFQ" numeric,
    "TUNAI_LQT" numeric,
    "TUNAI_SDQ" numeric,
    "TUNAI_SNK" numeric,
    "TUNAI_TDY" numeric,
    "TUNAI_ZKT" numeric,
    "NOMINAL_FI" numeric,
    "NOMINAL_ZF" numeric,
    "NOMINAL_AQQ" numeric,
    "NOMINAL_FDY" numeric,
    "NOMINAL_IFQ" numeric,
    "NOMINAL_LQT" numeric,
    "NOMINAL_SDQ" numeric,
    "NOMINAL_SNK" numeric,
    "NOMINAL_TDY" numeric,
    "NOMINAL_ZKT" numeric
);


ALTER TABLE public.raw_finance_rincian_c2 OWNER TO admin;

--
-- TOC entry 324 (class 1259 OID 329367)
-- Name: stg_c2_finance_rincian; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_c2_finance_rincian AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rincian_c2._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rincian_c2
        ), wajib_ifq_calc AS (
         SELECT c."LMG" AS instansi,
            count(*) AS wajib_ifq
           FROM (public.raw_c2 c
             JOIN ( SELECT max(raw_c2._airbyte_generation_id) AS last_generation_id
                   FROM public.raw_c2) cg ON ((c._airbyte_generation_id = cg.last_generation_id)))
          WHERE ((c."Status_Tabungan")::text = 'Paham'::text)
          GROUP BY c."LMG"
        )
 SELECT 'C2'::text AS kantor_id,
    r."INSTANSI" AS instansi,
    (COALESCE(w.wajib_ifq, (0)::bigint))::numeric AS wajib_ifq,
    r."TUNAI_FI" AS tunai_fi,
    r."TUNAI_ZF" AS tunai_zf,
    r."TUNAI_AQQ" AS tunai_aqq,
    r."TUNAI_FDY" AS tunai_fdy,
    r."TUNAI_IFQ" AS tunai_ifq,
    r."TUNAI_LQT" AS tunai_lqt,
    r."TUNAI_SDQ" AS tunai_sdq,
    r."TUNAI_SNK" AS tunai_snk,
    r."TUNAI_TDY" AS tunai_tdy,
    r."TUNAI_ZKT" AS tunai_zkt,
    r."NOMINAL_FI" AS nominal_fi,
    r."NOMINAL_ZF" AS nominal_zf,
    r."NOMINAL_AQQ" AS nominal_aqq,
    r."NOMINAL_FDY" AS nominal_fdy,
    r."NOMINAL_IFQ" AS nominal_ifq,
    r."NOMINAL_LQT" AS nominal_lqt,
    r."NOMINAL_SDQ" AS nominal_sdq,
    r."NOMINAL_SNK" AS nominal_snk,
    r."NOMINAL_TDY" AS nominal_tdy,
    r."NOMINAL_ZKT" AS nominal_zkt
   FROM ((public.raw_finance_rincian_c2 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
     LEFT JOIN wajib_ifq_calc w ON (((w.instansi)::text = (r."INSTANSI")::text)));


ALTER VIEW analytics.stg_c2_finance_rincian OWNER TO admin;

--
-- TOC entry 283 (class 1259 OID 299726)
-- Name: raw_finance_rincian_c3; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rincian_c3 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "INSTANSI" character varying,
    "TUNAI_FI" numeric,
    "TUNAI_ZF" numeric,
    "TUNAI_AQQ" numeric,
    "TUNAI_FDY" numeric,
    "TUNAI_IFQ" numeric,
    "TUNAI_LQT" numeric,
    "TUNAI_SDQ" numeric,
    "TUNAI_SNK" numeric,
    "TUNAI_TDY" numeric,
    "TUNAI_ZKT" numeric,
    "NOMINAL_FI" numeric,
    "NOMINAL_ZF" numeric,
    "NOMINAL_AQQ" numeric,
    "NOMINAL_FDY" numeric,
    "NOMINAL_IFQ" numeric,
    "NOMINAL_LQT" numeric,
    "NOMINAL_SDQ" numeric,
    "NOMINAL_SNK" numeric,
    "NOMINAL_TDY" numeric,
    "NOMINAL_ZKT" numeric
);


ALTER TABLE public.raw_finance_rincian_c3 OWNER TO admin;

--
-- TOC entry 328 (class 1259 OID 329387)
-- Name: stg_c3_finance_rincian; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_c3_finance_rincian AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rincian_c3._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rincian_c3
        ), wajib_ifq_calc AS (
         SELECT c."LMG" AS instansi,
            count(*) AS wajib_ifq
           FROM (public.raw_c3 c
             JOIN ( SELECT max(raw_c3._airbyte_generation_id) AS last_generation_id
                   FROM public.raw_c3) cg ON ((c._airbyte_generation_id = cg.last_generation_id)))
          WHERE ((c."Status_Tabungan")::text = 'Paham'::text)
          GROUP BY c."LMG"
        )
 SELECT 'C3'::text AS kantor_id,
    r."INSTANSI" AS instansi,
    (COALESCE(w.wajib_ifq, (0)::bigint))::numeric AS wajib_ifq,
    r."TUNAI_FI" AS tunai_fi,
    r."TUNAI_ZF" AS tunai_zf,
    r."TUNAI_AQQ" AS tunai_aqq,
    r."TUNAI_FDY" AS tunai_fdy,
    r."TUNAI_IFQ" AS tunai_ifq,
    r."TUNAI_LQT" AS tunai_lqt,
    r."TUNAI_SDQ" AS tunai_sdq,
    r."TUNAI_SNK" AS tunai_snk,
    r."TUNAI_TDY" AS tunai_tdy,
    r."TUNAI_ZKT" AS tunai_zkt,
    r."NOMINAL_FI" AS nominal_fi,
    r."NOMINAL_ZF" AS nominal_zf,
    r."NOMINAL_AQQ" AS nominal_aqq,
    r."NOMINAL_FDY" AS nominal_fdy,
    r."NOMINAL_IFQ" AS nominal_ifq,
    r."NOMINAL_LQT" AS nominal_lqt,
    r."NOMINAL_SDQ" AS nominal_sdq,
    r."NOMINAL_SNK" AS nominal_snk,
    r."NOMINAL_TDY" AS nominal_tdy,
    r."NOMINAL_ZKT" AS nominal_zkt
   FROM ((public.raw_finance_rincian_c3 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
     LEFT JOIN wajib_ifq_calc w ON (((w.instansi)::text = (r."INSTANSI")::text)));


ALTER VIEW analytics.stg_c3_finance_rincian OWNER TO admin;

--
-- TOC entry 285 (class 1259 OID 299751)
-- Name: raw_finance_rincian_c4; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rincian_c4 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "INSTANSI" character varying,
    "TUNAI_FI" numeric,
    "TUNAI_ZF" numeric,
    "TUNAI_AQQ" numeric,
    "TUNAI_FDY" numeric,
    "TUNAI_IFQ" numeric,
    "TUNAI_LQT" numeric,
    "TUNAI_SDQ" numeric,
    "TUNAI_SNK" numeric,
    "TUNAI_TDY" numeric,
    "TUNAI_ZKT" numeric,
    "NOMINAL_FI" numeric,
    "NOMINAL_ZF" numeric,
    "NOMINAL_AQQ" numeric,
    "NOMINAL_FDY" numeric,
    "NOMINAL_IFQ" numeric,
    "NOMINAL_LQT" numeric,
    "NOMINAL_SDQ" numeric,
    "NOMINAL_SNK" numeric,
    "NOMINAL_TDY" numeric,
    "NOMINAL_ZKT" numeric
);


ALTER TABLE public.raw_finance_rincian_c4 OWNER TO admin;

--
-- TOC entry 330 (class 1259 OID 329397)
-- Name: stg_c4_finance_rincian; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_c4_finance_rincian AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rincian_c4._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rincian_c4
        ), wajib_ifq_calc AS (
         SELECT c."LMG" AS instansi,
            count(*) AS wajib_ifq
           FROM (public.raw_c4 c
             JOIN ( SELECT max(raw_c4._airbyte_generation_id) AS last_generation_id
                   FROM public.raw_c4) cg ON ((c._airbyte_generation_id = cg.last_generation_id)))
          WHERE ((c."Status_Tabungan")::text = 'Paham'::text)
          GROUP BY c."LMG"
        )
 SELECT 'C4'::text AS kantor_id,
    r."INSTANSI" AS instansi,
    (COALESCE(w.wajib_ifq, (0)::bigint))::numeric AS wajib_ifq,
    r."TUNAI_FI" AS tunai_fi,
    r."TUNAI_ZF" AS tunai_zf,
    r."TUNAI_AQQ" AS tunai_aqq,
    r."TUNAI_FDY" AS tunai_fdy,
    r."TUNAI_IFQ" AS tunai_ifq,
    r."TUNAI_LQT" AS tunai_lqt,
    r."TUNAI_SDQ" AS tunai_sdq,
    r."TUNAI_SNK" AS tunai_snk,
    r."TUNAI_TDY" AS tunai_tdy,
    r."TUNAI_ZKT" AS tunai_zkt,
    r."NOMINAL_FI" AS nominal_fi,
    r."NOMINAL_ZF" AS nominal_zf,
    r."NOMINAL_AQQ" AS nominal_aqq,
    r."NOMINAL_FDY" AS nominal_fdy,
    r."NOMINAL_IFQ" AS nominal_ifq,
    r."NOMINAL_LQT" AS nominal_lqt,
    r."NOMINAL_SDQ" AS nominal_sdq,
    r."NOMINAL_SNK" AS nominal_snk,
    r."NOMINAL_TDY" AS nominal_tdy,
    r."NOMINAL_ZKT" AS nominal_zkt
   FROM ((public.raw_finance_rincian_c4 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
     LEFT JOIN wajib_ifq_calc w ON (((w.instansi)::text = (r."INSTANSI")::text)));


ALTER VIEW analytics.stg_c4_finance_rincian OWNER TO admin;

--
-- TOC entry 287 (class 1259 OID 299775)
-- Name: raw_finance_rincian_c5; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rincian_c5 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "INSTANSI" character varying,
    "TUNAI_FI" numeric,
    "TUNAI_ZF" numeric,
    "TUNAI_AQQ" numeric,
    "TUNAI_FDY" numeric,
    "TUNAI_IFQ" numeric,
    "TUNAI_LQT" numeric,
    "TUNAI_SDQ" numeric,
    "TUNAI_SNK" numeric,
    "TUNAI_TDY" numeric,
    "TUNAI_ZKT" numeric,
    "NOMINAL_FI" numeric,
    "NOMINAL_ZF" numeric,
    "NOMINAL_AQQ" numeric,
    "NOMINAL_FDY" numeric,
    "NOMINAL_IFQ" numeric,
    "NOMINAL_LQT" numeric,
    "NOMINAL_SDQ" numeric,
    "NOMINAL_SNK" numeric,
    "NOMINAL_TDY" numeric,
    "NOMINAL_ZKT" numeric
);


ALTER TABLE public.raw_finance_rincian_c5 OWNER TO admin;

--
-- TOC entry 332 (class 1259 OID 329407)
-- Name: stg_c5_finance_rincian; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_c5_finance_rincian AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rincian_c5._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rincian_c5
        ), wajib_ifq_calc AS (
         SELECT c."LMG" AS instansi,
            count(*) AS wajib_ifq
           FROM (public.raw_c5 c
             JOIN ( SELECT max(raw_c5._airbyte_generation_id) AS last_generation_id
                   FROM public.raw_c5) cg ON ((c._airbyte_generation_id = cg.last_generation_id)))
          WHERE ((c."Status_Tabungan")::text = 'Paham'::text)
          GROUP BY c."LMG"
        )
 SELECT 'C5'::text AS kantor_id,
    r."INSTANSI" AS instansi,
    (COALESCE(w.wajib_ifq, (0)::bigint))::numeric AS wajib_ifq,
    r."TUNAI_FI" AS tunai_fi,
    r."TUNAI_ZF" AS tunai_zf,
    r."TUNAI_AQQ" AS tunai_aqq,
    r."TUNAI_FDY" AS tunai_fdy,
    r."TUNAI_IFQ" AS tunai_ifq,
    r."TUNAI_LQT" AS tunai_lqt,
    r."TUNAI_SDQ" AS tunai_sdq,
    r."TUNAI_SNK" AS tunai_snk,
    r."TUNAI_TDY" AS tunai_tdy,
    r."TUNAI_ZKT" AS tunai_zkt,
    r."NOMINAL_FI" AS nominal_fi,
    r."NOMINAL_ZF" AS nominal_zf,
    r."NOMINAL_AQQ" AS nominal_aqq,
    r."NOMINAL_FDY" AS nominal_fdy,
    r."NOMINAL_IFQ" AS nominal_ifq,
    r."NOMINAL_LQT" AS nominal_lqt,
    r."NOMINAL_SDQ" AS nominal_sdq,
    r."NOMINAL_SNK" AS nominal_snk,
    r."NOMINAL_TDY" AS nominal_tdy,
    r."NOMINAL_ZKT" AS nominal_zkt
   FROM ((public.raw_finance_rincian_c5 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
     LEFT JOIN wajib_ifq_calc w ON (((w.instansi)::text = (r."INSTANSI")::text)));


ALTER VIEW analytics.stg_c5_finance_rincian OWNER TO admin;

--
-- TOC entry 289 (class 1259 OID 299799)
-- Name: raw_finance_rincian_c6; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rincian_c6 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "INSTANSI" character varying,
    "TUNAI_FI" numeric,
    "TUNAI_ZF" numeric,
    "TUNAI_AQQ" numeric,
    "TUNAI_FDY" numeric,
    "TUNAI_IFQ" numeric,
    "TUNAI_LQT" numeric,
    "TUNAI_SDQ" numeric,
    "TUNAI_SNK" numeric,
    "TUNAI_TDY" numeric,
    "TUNAI_ZKT" numeric,
    "NOMINAL_FI" numeric,
    "NOMINAL_ZF" numeric,
    "NOMINAL_AQQ" numeric,
    "NOMINAL_FDY" numeric,
    "NOMINAL_IFQ" numeric,
    "NOMINAL_LQT" numeric,
    "NOMINAL_SDQ" numeric,
    "NOMINAL_SNK" numeric,
    "NOMINAL_TDY" numeric,
    "NOMINAL_ZKT" numeric
);


ALTER TABLE public.raw_finance_rincian_c6 OWNER TO admin;

--
-- TOC entry 334 (class 1259 OID 329417)
-- Name: stg_c6_finance_rincian; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_c6_finance_rincian AS
 WITH latest_pull AS (
         SELECT max(raw_finance_rincian_c6._airbyte_generation_id) AS last_generation_id
           FROM public.raw_finance_rincian_c6
        ), wajib_ifq_calc AS (
         SELECT c."LMG" AS instansi,
            count(*) AS wajib_ifq
           FROM (public.raw_c6 c
             JOIN ( SELECT max(raw_c6._airbyte_generation_id) AS last_generation_id
                   FROM public.raw_c6) cg ON ((c._airbyte_generation_id = cg.last_generation_id)))
          WHERE ((c."Status_Tabungan")::text = 'Paham'::text)
          GROUP BY c."LMG"
        )
 SELECT 'C6'::text AS kantor_id,
    r."INSTANSI" AS instansi,
    (COALESCE(w.wajib_ifq, (0)::bigint))::numeric AS wajib_ifq,
    r."TUNAI_FI" AS tunai_fi,
    r."TUNAI_ZF" AS tunai_zf,
    r."TUNAI_AQQ" AS tunai_aqq,
    r."TUNAI_FDY" AS tunai_fdy,
    r."TUNAI_IFQ" AS tunai_ifq,
    r."TUNAI_LQT" AS tunai_lqt,
    r."TUNAI_SDQ" AS tunai_sdq,
    r."TUNAI_SNK" AS tunai_snk,
    r."TUNAI_TDY" AS tunai_tdy,
    r."TUNAI_ZKT" AS tunai_zkt,
    r."NOMINAL_FI" AS nominal_fi,
    r."NOMINAL_ZF" AS nominal_zf,
    r."NOMINAL_AQQ" AS nominal_aqq,
    r."NOMINAL_FDY" AS nominal_fdy,
    r."NOMINAL_IFQ" AS nominal_ifq,
    r."NOMINAL_LQT" AS nominal_lqt,
    r."NOMINAL_SDQ" AS nominal_sdq,
    r."NOMINAL_SNK" AS nominal_snk,
    r."NOMINAL_TDY" AS nominal_tdy,
    r."NOMINAL_ZKT" AS nominal_zkt
   FROM ((public.raw_finance_rincian_c6 r
     JOIN latest_pull lp ON ((r._airbyte_generation_id = lp.last_generation_id)))
     LEFT JOIN wajib_ifq_calc w ON (((w.instansi)::text = (r."INSTANSI")::text)));


ALTER VIEW analytics.stg_c6_finance_rincian OWNER TO admin;

--
-- TOC entry 337 (class 1259 OID 329432)
-- Name: mart_finance_rincian; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.mart_finance_rincian AS
 SELECT stg_a1_finance_rincian.kantor_id,
    stg_a1_finance_rincian.instansi,
    stg_a1_finance_rincian.wajib_ifq,
    stg_a1_finance_rincian.tunai_fi,
    stg_a1_finance_rincian.tunai_zf,
    stg_a1_finance_rincian.tunai_aqq,
    stg_a1_finance_rincian.tunai_fdy,
    stg_a1_finance_rincian.tunai_ifq,
    stg_a1_finance_rincian.tunai_lqt,
    stg_a1_finance_rincian.tunai_sdq,
    stg_a1_finance_rincian.tunai_snk,
    stg_a1_finance_rincian.tunai_tdy,
    stg_a1_finance_rincian.tunai_zkt,
    stg_a1_finance_rincian.nominal_fi,
    stg_a1_finance_rincian.nominal_zf,
    stg_a1_finance_rincian.nominal_aqq,
    stg_a1_finance_rincian.nominal_fdy,
    stg_a1_finance_rincian.nominal_ifq,
    stg_a1_finance_rincian.nominal_lqt,
    stg_a1_finance_rincian.nominal_sdq,
    stg_a1_finance_rincian.nominal_snk,
    stg_a1_finance_rincian.nominal_tdy,
    stg_a1_finance_rincian.nominal_zkt
   FROM analytics.stg_a1_finance_rincian
UNION ALL
 SELECT stg_a2_finance_rincian.kantor_id,
    stg_a2_finance_rincian.instansi,
    stg_a2_finance_rincian.wajib_ifq,
    stg_a2_finance_rincian.tunai_fi,
    stg_a2_finance_rincian.tunai_zf,
    stg_a2_finance_rincian.tunai_aqq,
    stg_a2_finance_rincian.tunai_fdy,
    stg_a2_finance_rincian.tunai_ifq,
    stg_a2_finance_rincian.tunai_lqt,
    stg_a2_finance_rincian.tunai_sdq,
    stg_a2_finance_rincian.tunai_snk,
    stg_a2_finance_rincian.tunai_tdy,
    stg_a2_finance_rincian.tunai_zkt,
    stg_a2_finance_rincian.nominal_fi,
    stg_a2_finance_rincian.nominal_zf,
    stg_a2_finance_rincian.nominal_aqq,
    stg_a2_finance_rincian.nominal_fdy,
    stg_a2_finance_rincian.nominal_ifq,
    stg_a2_finance_rincian.nominal_lqt,
    stg_a2_finance_rincian.nominal_sdq,
    stg_a2_finance_rincian.nominal_snk,
    stg_a2_finance_rincian.nominal_tdy,
    stg_a2_finance_rincian.nominal_zkt
   FROM analytics.stg_a2_finance_rincian
UNION ALL
 SELECT stg_a3_finance_rincian.kantor_id,
    stg_a3_finance_rincian.instansi,
    stg_a3_finance_rincian.wajib_ifq,
    stg_a3_finance_rincian.tunai_fi,
    stg_a3_finance_rincian.tunai_zf,
    stg_a3_finance_rincian.tunai_aqq,
    stg_a3_finance_rincian.tunai_fdy,
    stg_a3_finance_rincian.tunai_ifq,
    stg_a3_finance_rincian.tunai_lqt,
    stg_a3_finance_rincian.tunai_sdq,
    stg_a3_finance_rincian.tunai_snk,
    stg_a3_finance_rincian.tunai_tdy,
    stg_a3_finance_rincian.tunai_zkt,
    stg_a3_finance_rincian.nominal_fi,
    stg_a3_finance_rincian.nominal_zf,
    stg_a3_finance_rincian.nominal_aqq,
    stg_a3_finance_rincian.nominal_fdy,
    stg_a3_finance_rincian.nominal_ifq,
    stg_a3_finance_rincian.nominal_lqt,
    stg_a3_finance_rincian.nominal_sdq,
    stg_a3_finance_rincian.nominal_snk,
    stg_a3_finance_rincian.nominal_tdy,
    stg_a3_finance_rincian.nominal_zkt
   FROM analytics.stg_a3_finance_rincian
UNION ALL
 SELECT stg_b1_finance_rincian.kantor_id,
    stg_b1_finance_rincian.instansi,
    stg_b1_finance_rincian.wajib_ifq,
    stg_b1_finance_rincian.tunai_fi,
    stg_b1_finance_rincian.tunai_zf,
    stg_b1_finance_rincian.tunai_aqq,
    stg_b1_finance_rincian.tunai_fdy,
    stg_b1_finance_rincian.tunai_ifq,
    stg_b1_finance_rincian.tunai_lqt,
    stg_b1_finance_rincian.tunai_sdq,
    stg_b1_finance_rincian.tunai_snk,
    stg_b1_finance_rincian.tunai_tdy,
    stg_b1_finance_rincian.tunai_zkt,
    stg_b1_finance_rincian.nominal_fi,
    stg_b1_finance_rincian.nominal_zf,
    stg_b1_finance_rincian.nominal_aqq,
    stg_b1_finance_rincian.nominal_fdy,
    stg_b1_finance_rincian.nominal_ifq,
    stg_b1_finance_rincian.nominal_lqt,
    stg_b1_finance_rincian.nominal_sdq,
    stg_b1_finance_rincian.nominal_snk,
    stg_b1_finance_rincian.nominal_tdy,
    stg_b1_finance_rincian.nominal_zkt
   FROM analytics.stg_b1_finance_rincian
UNION ALL
 SELECT stg_b2_finance_rincian.kantor_id,
    stg_b2_finance_rincian.instansi,
    stg_b2_finance_rincian.wajib_ifq,
    stg_b2_finance_rincian.tunai_fi,
    stg_b2_finance_rincian.tunai_zf,
    stg_b2_finance_rincian.tunai_aqq,
    stg_b2_finance_rincian.tunai_fdy,
    stg_b2_finance_rincian.tunai_ifq,
    stg_b2_finance_rincian.tunai_lqt,
    stg_b2_finance_rincian.tunai_sdq,
    stg_b2_finance_rincian.tunai_snk,
    stg_b2_finance_rincian.tunai_tdy,
    stg_b2_finance_rincian.tunai_zkt,
    stg_b2_finance_rincian.nominal_fi,
    stg_b2_finance_rincian.nominal_zf,
    stg_b2_finance_rincian.nominal_aqq,
    stg_b2_finance_rincian.nominal_fdy,
    stg_b2_finance_rincian.nominal_ifq,
    stg_b2_finance_rincian.nominal_lqt,
    stg_b2_finance_rincian.nominal_sdq,
    stg_b2_finance_rincian.nominal_snk,
    stg_b2_finance_rincian.nominal_tdy,
    stg_b2_finance_rincian.nominal_zkt
   FROM analytics.stg_b2_finance_rincian
UNION ALL
 SELECT stg_b3_finance_rincian.kantor_id,
    stg_b3_finance_rincian.instansi,
    stg_b3_finance_rincian.wajib_ifq,
    stg_b3_finance_rincian.tunai_fi,
    stg_b3_finance_rincian.tunai_zf,
    stg_b3_finance_rincian.tunai_aqq,
    stg_b3_finance_rincian.tunai_fdy,
    stg_b3_finance_rincian.tunai_ifq,
    stg_b3_finance_rincian.tunai_lqt,
    stg_b3_finance_rincian.tunai_sdq,
    stg_b3_finance_rincian.tunai_snk,
    stg_b3_finance_rincian.tunai_tdy,
    stg_b3_finance_rincian.tunai_zkt,
    stg_b3_finance_rincian.nominal_fi,
    stg_b3_finance_rincian.nominal_zf,
    stg_b3_finance_rincian.nominal_aqq,
    stg_b3_finance_rincian.nominal_fdy,
    stg_b3_finance_rincian.nominal_ifq,
    stg_b3_finance_rincian.nominal_lqt,
    stg_b3_finance_rincian.nominal_sdq,
    stg_b3_finance_rincian.nominal_snk,
    stg_b3_finance_rincian.nominal_tdy,
    stg_b3_finance_rincian.nominal_zkt
   FROM analytics.stg_b3_finance_rincian
UNION ALL
 SELECT stg_b4_finance_rincian.kantor_id,
    stg_b4_finance_rincian.instansi,
    stg_b4_finance_rincian.wajib_ifq,
    stg_b4_finance_rincian.tunai_fi,
    stg_b4_finance_rincian.tunai_zf,
    stg_b4_finance_rincian.tunai_aqq,
    stg_b4_finance_rincian.tunai_fdy,
    stg_b4_finance_rincian.tunai_ifq,
    stg_b4_finance_rincian.tunai_lqt,
    stg_b4_finance_rincian.tunai_sdq,
    stg_b4_finance_rincian.tunai_snk,
    stg_b4_finance_rincian.tunai_tdy,
    stg_b4_finance_rincian.tunai_zkt,
    stg_b4_finance_rincian.nominal_fi,
    stg_b4_finance_rincian.nominal_zf,
    stg_b4_finance_rincian.nominal_aqq,
    stg_b4_finance_rincian.nominal_fdy,
    stg_b4_finance_rincian.nominal_ifq,
    stg_b4_finance_rincian.nominal_lqt,
    stg_b4_finance_rincian.nominal_sdq,
    stg_b4_finance_rincian.nominal_snk,
    stg_b4_finance_rincian.nominal_tdy,
    stg_b4_finance_rincian.nominal_zkt
   FROM analytics.stg_b4_finance_rincian
UNION ALL
 SELECT stg_b5_finance_rincian.kantor_id,
    stg_b5_finance_rincian.instansi,
    stg_b5_finance_rincian.wajib_ifq,
    stg_b5_finance_rincian.tunai_fi,
    stg_b5_finance_rincian.tunai_zf,
    stg_b5_finance_rincian.tunai_aqq,
    stg_b5_finance_rincian.tunai_fdy,
    stg_b5_finance_rincian.tunai_ifq,
    stg_b5_finance_rincian.tunai_lqt,
    stg_b5_finance_rincian.tunai_sdq,
    stg_b5_finance_rincian.tunai_snk,
    stg_b5_finance_rincian.tunai_tdy,
    stg_b5_finance_rincian.tunai_zkt,
    stg_b5_finance_rincian.nominal_fi,
    stg_b5_finance_rincian.nominal_zf,
    stg_b5_finance_rincian.nominal_aqq,
    stg_b5_finance_rincian.nominal_fdy,
    stg_b5_finance_rincian.nominal_ifq,
    stg_b5_finance_rincian.nominal_lqt,
    stg_b5_finance_rincian.nominal_sdq,
    stg_b5_finance_rincian.nominal_snk,
    stg_b5_finance_rincian.nominal_tdy,
    stg_b5_finance_rincian.nominal_zkt
   FROM analytics.stg_b5_finance_rincian
UNION ALL
 SELECT stg_c1_finance_rincian.kantor_id,
    stg_c1_finance_rincian.instansi,
    stg_c1_finance_rincian.wajib_ifq,
    stg_c1_finance_rincian.tunai_fi,
    stg_c1_finance_rincian.tunai_zf,
    stg_c1_finance_rincian.tunai_aqq,
    stg_c1_finance_rincian.tunai_fdy,
    stg_c1_finance_rincian.tunai_ifq,
    stg_c1_finance_rincian.tunai_lqt,
    stg_c1_finance_rincian.tunai_sdq,
    stg_c1_finance_rincian.tunai_snk,
    stg_c1_finance_rincian.tunai_tdy,
    stg_c1_finance_rincian.tunai_zkt,
    stg_c1_finance_rincian.nominal_fi,
    stg_c1_finance_rincian.nominal_zf,
    stg_c1_finance_rincian.nominal_aqq,
    stg_c1_finance_rincian.nominal_fdy,
    stg_c1_finance_rincian.nominal_ifq,
    stg_c1_finance_rincian.nominal_lqt,
    stg_c1_finance_rincian.nominal_sdq,
    stg_c1_finance_rincian.nominal_snk,
    stg_c1_finance_rincian.nominal_tdy,
    stg_c1_finance_rincian.nominal_zkt
   FROM analytics.stg_c1_finance_rincian
UNION ALL
 SELECT stg_c2_finance_rincian.kantor_id,
    stg_c2_finance_rincian.instansi,
    stg_c2_finance_rincian.wajib_ifq,
    stg_c2_finance_rincian.tunai_fi,
    stg_c2_finance_rincian.tunai_zf,
    stg_c2_finance_rincian.tunai_aqq,
    stg_c2_finance_rincian.tunai_fdy,
    stg_c2_finance_rincian.tunai_ifq,
    stg_c2_finance_rincian.tunai_lqt,
    stg_c2_finance_rincian.tunai_sdq,
    stg_c2_finance_rincian.tunai_snk,
    stg_c2_finance_rincian.tunai_tdy,
    stg_c2_finance_rincian.tunai_zkt,
    stg_c2_finance_rincian.nominal_fi,
    stg_c2_finance_rincian.nominal_zf,
    stg_c2_finance_rincian.nominal_aqq,
    stg_c2_finance_rincian.nominal_fdy,
    stg_c2_finance_rincian.nominal_ifq,
    stg_c2_finance_rincian.nominal_lqt,
    stg_c2_finance_rincian.nominal_sdq,
    stg_c2_finance_rincian.nominal_snk,
    stg_c2_finance_rincian.nominal_tdy,
    stg_c2_finance_rincian.nominal_zkt
   FROM analytics.stg_c2_finance_rincian
UNION ALL
 SELECT stg_c3_finance_rincian.kantor_id,
    stg_c3_finance_rincian.instansi,
    stg_c3_finance_rincian.wajib_ifq,
    stg_c3_finance_rincian.tunai_fi,
    stg_c3_finance_rincian.tunai_zf,
    stg_c3_finance_rincian.tunai_aqq,
    stg_c3_finance_rincian.tunai_fdy,
    stg_c3_finance_rincian.tunai_ifq,
    stg_c3_finance_rincian.tunai_lqt,
    stg_c3_finance_rincian.tunai_sdq,
    stg_c3_finance_rincian.tunai_snk,
    stg_c3_finance_rincian.tunai_tdy,
    stg_c3_finance_rincian.tunai_zkt,
    stg_c3_finance_rincian.nominal_fi,
    stg_c3_finance_rincian.nominal_zf,
    stg_c3_finance_rincian.nominal_aqq,
    stg_c3_finance_rincian.nominal_fdy,
    stg_c3_finance_rincian.nominal_ifq,
    stg_c3_finance_rincian.nominal_lqt,
    stg_c3_finance_rincian.nominal_sdq,
    stg_c3_finance_rincian.nominal_snk,
    stg_c3_finance_rincian.nominal_tdy,
    stg_c3_finance_rincian.nominal_zkt
   FROM analytics.stg_c3_finance_rincian
UNION ALL
 SELECT stg_c4_finance_rincian.kantor_id,
    stg_c4_finance_rincian.instansi,
    stg_c4_finance_rincian.wajib_ifq,
    stg_c4_finance_rincian.tunai_fi,
    stg_c4_finance_rincian.tunai_zf,
    stg_c4_finance_rincian.tunai_aqq,
    stg_c4_finance_rincian.tunai_fdy,
    stg_c4_finance_rincian.tunai_ifq,
    stg_c4_finance_rincian.tunai_lqt,
    stg_c4_finance_rincian.tunai_sdq,
    stg_c4_finance_rincian.tunai_snk,
    stg_c4_finance_rincian.tunai_tdy,
    stg_c4_finance_rincian.tunai_zkt,
    stg_c4_finance_rincian.nominal_fi,
    stg_c4_finance_rincian.nominal_zf,
    stg_c4_finance_rincian.nominal_aqq,
    stg_c4_finance_rincian.nominal_fdy,
    stg_c4_finance_rincian.nominal_ifq,
    stg_c4_finance_rincian.nominal_lqt,
    stg_c4_finance_rincian.nominal_sdq,
    stg_c4_finance_rincian.nominal_snk,
    stg_c4_finance_rincian.nominal_tdy,
    stg_c4_finance_rincian.nominal_zkt
   FROM analytics.stg_c4_finance_rincian
UNION ALL
 SELECT stg_c5_finance_rincian.kantor_id,
    stg_c5_finance_rincian.instansi,
    stg_c5_finance_rincian.wajib_ifq,
    stg_c5_finance_rincian.tunai_fi,
    stg_c5_finance_rincian.tunai_zf,
    stg_c5_finance_rincian.tunai_aqq,
    stg_c5_finance_rincian.tunai_fdy,
    stg_c5_finance_rincian.tunai_ifq,
    stg_c5_finance_rincian.tunai_lqt,
    stg_c5_finance_rincian.tunai_sdq,
    stg_c5_finance_rincian.tunai_snk,
    stg_c5_finance_rincian.tunai_tdy,
    stg_c5_finance_rincian.tunai_zkt,
    stg_c5_finance_rincian.nominal_fi,
    stg_c5_finance_rincian.nominal_zf,
    stg_c5_finance_rincian.nominal_aqq,
    stg_c5_finance_rincian.nominal_fdy,
    stg_c5_finance_rincian.nominal_ifq,
    stg_c5_finance_rincian.nominal_lqt,
    stg_c5_finance_rincian.nominal_sdq,
    stg_c5_finance_rincian.nominal_snk,
    stg_c5_finance_rincian.nominal_tdy,
    stg_c5_finance_rincian.nominal_zkt
   FROM analytics.stg_c5_finance_rincian
UNION ALL
 SELECT stg_c6_finance_rincian.kantor_id,
    stg_c6_finance_rincian.instansi,
    stg_c6_finance_rincian.wajib_ifq,
    stg_c6_finance_rincian.tunai_fi,
    stg_c6_finance_rincian.tunai_zf,
    stg_c6_finance_rincian.tunai_aqq,
    stg_c6_finance_rincian.tunai_fdy,
    stg_c6_finance_rincian.tunai_ifq,
    stg_c6_finance_rincian.tunai_lqt,
    stg_c6_finance_rincian.tunai_sdq,
    stg_c6_finance_rincian.tunai_snk,
    stg_c6_finance_rincian.tunai_tdy,
    stg_c6_finance_rincian.tunai_zkt,
    stg_c6_finance_rincian.nominal_fi,
    stg_c6_finance_rincian.nominal_zf,
    stg_c6_finance_rincian.nominal_aqq,
    stg_c6_finance_rincian.nominal_fdy,
    stg_c6_finance_rincian.nominal_ifq,
    stg_c6_finance_rincian.nominal_lqt,
    stg_c6_finance_rincian.nominal_sdq,
    stg_c6_finance_rincian.nominal_snk,
    stg_c6_finance_rincian.nominal_tdy,
    stg_c6_finance_rincian.nominal_zkt
   FROM analytics.stg_c6_finance_rincian;


ALTER VIEW analytics.mart_finance_rincian OWNER TO admin;

--
-- TOC entry 340 (class 1259 OID 363938)
-- Name: stg_all_capil; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_all_capil AS
 SELECT r.kantor_id,
    r."K",
    r."JK",
    r."LMG",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Status_Aktivitas",
    r."Status_Tabungan"
   FROM analytics.stg_a1_capil r
UNION ALL
 SELECT r.kantor_id,
    r."K",
    r."JK",
    r."LMG",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Status_Aktivitas",
    r."Status_Tabungan"
   FROM analytics.stg_a2_capil r
UNION ALL
 SELECT r.kantor_id,
    r."K",
    r."JK",
    r."LMG",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Status_Aktivitas",
    r."Status_Tabungan"
   FROM analytics.stg_a3_capil r
UNION ALL
 SELECT r.kantor_id,
    r."K",
    r."JK",
    r."LMG",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Status_Aktivitas",
    r."Status_Tabungan"
   FROM analytics.stg_b1_capil r
UNION ALL
 SELECT r.kantor_id,
    r."K",
    r."JK",
    r."LMG",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Status_Aktivitas",
    r."Status_Tabungan"
   FROM analytics.stg_b2_capil r
UNION ALL
 SELECT r.kantor_id,
    r."K",
    r."JK",
    r."LMG",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Status_Aktivitas",
    r."Status_Tabungan"
   FROM analytics.stg_b3_capil r
UNION ALL
 SELECT r.kantor_id,
    r."K",
    r."JK",
    r."LMG",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Status_Aktivitas",
    r."Status_Tabungan"
   FROM analytics.stg_b4_capil r
UNION ALL
 SELECT r.kantor_id,
    r."K",
    r."JK",
    r."LMG",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Status_Aktivitas",
    r."Status_Tabungan"
   FROM analytics.stg_b5_capil r
UNION ALL
 SELECT r.kantor_id,
    r."K",
    r."JK",
    r."LMG",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Status_Aktivitas",
    r."Status_Tabungan"
   FROM analytics.stg_c1_capil r
UNION ALL
 SELECT r.kantor_id,
    r."K",
    r."JK",
    r."LMG",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Status_Aktivitas",
    r."Status_Tabungan"
   FROM analytics.stg_c2_capil r
UNION ALL
 SELECT r.kantor_id,
    r."K",
    r."JK",
    r."LMG",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Status_Aktivitas",
    r."Status_Tabungan"
   FROM analytics.stg_c3_capil r
UNION ALL
 SELECT r.kantor_id,
    r."K",
    r."JK",
    r."LMG",
    r."Th_Integrasi",
    r."Bln_Integrasi",
    r."Status_Aktivitas",
    r."Status_Tabungan"
   FROM analytics.stg_c4_capil r;


ALTER VIEW analytics.stg_all_capil OWNER TO admin;

--
-- TOC entry 338 (class 1259 OID 332366)
-- Name: stg_all_finance_rekap; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_all_finance_rekap AS
 SELECT r.kantor_id,
    r.jenis,
    r.disetor,
    r.dikelola_kanwil,
    r.pembulatan_setor,
    r.total_100_persen
   FROM analytics.stg_a1_finance_rekap r
UNION ALL
 SELECT r.kantor_id,
    r.jenis,
    r.disetor,
    r.dikelola_kanwil,
    r.pembulatan_setor,
    r.total_100_persen
   FROM analytics.stg_a2_finance_rekap r
UNION ALL
 SELECT r.kantor_id,
    r.jenis,
    r.disetor,
    r.dikelola_kanwil,
    r.pembulatan_setor,
    r.total_100_persen
   FROM analytics.stg_a3_finance_rekap r
UNION ALL
 SELECT r.kantor_id,
    r.jenis,
    r.disetor,
    r.dikelola_kanwil,
    r.pembulatan_setor,
    r.total_100_persen
   FROM analytics.stg_b1_finance_rekap r
UNION ALL
 SELECT r.kantor_id,
    r.jenis,
    r.disetor,
    r.dikelola_kanwil,
    r.pembulatan_setor,
    r.total_100_persen
   FROM analytics.stg_b2_finance_rekap r
UNION ALL
 SELECT r.kantor_id,
    r.jenis,
    r.disetor,
    r.dikelola_kanwil,
    r.pembulatan_setor,
    r.total_100_persen
   FROM analytics.stg_b3_finance_rekap r
UNION ALL
 SELECT r.kantor_id,
    r.jenis,
    r.disetor,
    r.dikelola_kanwil,
    r.pembulatan_setor,
    r.total_100_persen
   FROM analytics.stg_b4_finance_rekap r
UNION ALL
 SELECT r.kantor_id,
    r.jenis,
    r.disetor,
    r.dikelola_kanwil,
    r.pembulatan_setor,
    r.total_100_persen
   FROM analytics.stg_b5_finance_rekap r
UNION ALL
 SELECT r.kantor_id,
    r.jenis,
    r.disetor,
    r.dikelola_kanwil,
    r.pembulatan_setor,
    r.total_100_persen
   FROM analytics.stg_c1_finance_rekap r
UNION ALL
 SELECT r.kantor_id,
    r.jenis,
    r.disetor,
    r.dikelola_kanwil,
    r.pembulatan_setor,
    r.total_100_persen
   FROM analytics.stg_c2_finance_rekap r
UNION ALL
 SELECT r.kantor_id,
    r.jenis,
    r.disetor,
    r.dikelola_kanwil,
    r.pembulatan_setor,
    r.total_100_persen
   FROM analytics.stg_c3_finance_rekap r
UNION ALL
 SELECT r.kantor_id,
    r.jenis,
    r.disetor,
    r.dikelola_kanwil,
    r.pembulatan_setor,
    r.total_100_persen
   FROM analytics.stg_c4_finance_rekap r;


ALTER VIEW analytics.stg_all_finance_rekap OWNER TO admin;

--
-- TOC entry 339 (class 1259 OID 332373)
-- Name: stg_all_finance_rincian; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_all_finance_rincian AS
 SELECT r.kantor_id,
    r.instansi,
    r.wajib_ifq,
    r.tunai_fi,
    r.tunai_zf,
    r.tunai_aqq,
    r.tunai_fdy,
    r.tunai_ifq,
    r.tunai_lqt,
    r.tunai_sdq,
    r.tunai_snk,
    r.tunai_tdy,
    r.tunai_zkt,
    r.nominal_fi,
    r.nominal_zf,
    r.nominal_aqq,
    r.nominal_fdy,
    r.nominal_ifq,
    r.nominal_lqt,
    r.nominal_sdq,
    r.nominal_snk,
    r.nominal_tdy,
    r.nominal_zkt
   FROM analytics.stg_a1_finance_rincian r
UNION ALL
 SELECT r.kantor_id,
    r.instansi,
    r.wajib_ifq,
    r.tunai_fi,
    r.tunai_zf,
    r.tunai_aqq,
    r.tunai_fdy,
    r.tunai_ifq,
    r.tunai_lqt,
    r.tunai_sdq,
    r.tunai_snk,
    r.tunai_tdy,
    r.tunai_zkt,
    r.nominal_fi,
    r.nominal_zf,
    r.nominal_aqq,
    r.nominal_fdy,
    r.nominal_ifq,
    r.nominal_lqt,
    r.nominal_sdq,
    r.nominal_snk,
    r.nominal_tdy,
    r.nominal_zkt
   FROM analytics.stg_a2_finance_rincian r
UNION ALL
 SELECT r.kantor_id,
    r.instansi,
    r.wajib_ifq,
    r.tunai_fi,
    r.tunai_zf,
    r.tunai_aqq,
    r.tunai_fdy,
    r.tunai_ifq,
    r.tunai_lqt,
    r.tunai_sdq,
    r.tunai_snk,
    r.tunai_tdy,
    r.tunai_zkt,
    r.nominal_fi,
    r.nominal_zf,
    r.nominal_aqq,
    r.nominal_fdy,
    r.nominal_ifq,
    r.nominal_lqt,
    r.nominal_sdq,
    r.nominal_snk,
    r.nominal_tdy,
    r.nominal_zkt
   FROM analytics.stg_a3_finance_rincian r
UNION ALL
 SELECT r.kantor_id,
    r.instansi,
    r.wajib_ifq,
    r.tunai_fi,
    r.tunai_zf,
    r.tunai_aqq,
    r.tunai_fdy,
    r.tunai_ifq,
    r.tunai_lqt,
    r.tunai_sdq,
    r.tunai_snk,
    r.tunai_tdy,
    r.tunai_zkt,
    r.nominal_fi,
    r.nominal_zf,
    r.nominal_aqq,
    r.nominal_fdy,
    r.nominal_ifq,
    r.nominal_lqt,
    r.nominal_sdq,
    r.nominal_snk,
    r.nominal_tdy,
    r.nominal_zkt
   FROM analytics.stg_b1_finance_rincian r
UNION ALL
 SELECT r.kantor_id,
    r.instansi,
    r.wajib_ifq,
    r.tunai_fi,
    r.tunai_zf,
    r.tunai_aqq,
    r.tunai_fdy,
    r.tunai_ifq,
    r.tunai_lqt,
    r.tunai_sdq,
    r.tunai_snk,
    r.tunai_tdy,
    r.tunai_zkt,
    r.nominal_fi,
    r.nominal_zf,
    r.nominal_aqq,
    r.nominal_fdy,
    r.nominal_ifq,
    r.nominal_lqt,
    r.nominal_sdq,
    r.nominal_snk,
    r.nominal_tdy,
    r.nominal_zkt
   FROM analytics.stg_b2_finance_rincian r
UNION ALL
 SELECT r.kantor_id,
    r.instansi,
    r.wajib_ifq,
    r.tunai_fi,
    r.tunai_zf,
    r.tunai_aqq,
    r.tunai_fdy,
    r.tunai_ifq,
    r.tunai_lqt,
    r.tunai_sdq,
    r.tunai_snk,
    r.tunai_tdy,
    r.tunai_zkt,
    r.nominal_fi,
    r.nominal_zf,
    r.nominal_aqq,
    r.nominal_fdy,
    r.nominal_ifq,
    r.nominal_lqt,
    r.nominal_sdq,
    r.nominal_snk,
    r.nominal_tdy,
    r.nominal_zkt
   FROM analytics.stg_b3_finance_rincian r
UNION ALL
 SELECT r.kantor_id,
    r.instansi,
    r.wajib_ifq,
    r.tunai_fi,
    r.tunai_zf,
    r.tunai_aqq,
    r.tunai_fdy,
    r.tunai_ifq,
    r.tunai_lqt,
    r.tunai_sdq,
    r.tunai_snk,
    r.tunai_tdy,
    r.tunai_zkt,
    r.nominal_fi,
    r.nominal_zf,
    r.nominal_aqq,
    r.nominal_fdy,
    r.nominal_ifq,
    r.nominal_lqt,
    r.nominal_sdq,
    r.nominal_snk,
    r.nominal_tdy,
    r.nominal_zkt
   FROM analytics.stg_b4_finance_rincian r
UNION ALL
 SELECT r.kantor_id,
    r.instansi,
    r.wajib_ifq,
    r.tunai_fi,
    r.tunai_zf,
    r.tunai_aqq,
    r.tunai_fdy,
    r.tunai_ifq,
    r.tunai_lqt,
    r.tunai_sdq,
    r.tunai_snk,
    r.tunai_tdy,
    r.tunai_zkt,
    r.nominal_fi,
    r.nominal_zf,
    r.nominal_aqq,
    r.nominal_fdy,
    r.nominal_ifq,
    r.nominal_lqt,
    r.nominal_sdq,
    r.nominal_snk,
    r.nominal_tdy,
    r.nominal_zkt
   FROM analytics.stg_b5_finance_rincian r
UNION ALL
 SELECT r.kantor_id,
    r.instansi,
    r.wajib_ifq,
    r.tunai_fi,
    r.tunai_zf,
    r.tunai_aqq,
    r.tunai_fdy,
    r.tunai_ifq,
    r.tunai_lqt,
    r.tunai_sdq,
    r.tunai_snk,
    r.tunai_tdy,
    r.tunai_zkt,
    r.nominal_fi,
    r.nominal_zf,
    r.nominal_aqq,
    r.nominal_fdy,
    r.nominal_ifq,
    r.nominal_lqt,
    r.nominal_sdq,
    r.nominal_snk,
    r.nominal_tdy,
    r.nominal_zkt
   FROM analytics.stg_c1_finance_rincian r
UNION ALL
 SELECT r.kantor_id,
    r.instansi,
    r.wajib_ifq,
    r.tunai_fi,
    r.tunai_zf,
    r.tunai_aqq,
    r.tunai_fdy,
    r.tunai_ifq,
    r.tunai_lqt,
    r.tunai_sdq,
    r.tunai_snk,
    r.tunai_tdy,
    r.tunai_zkt,
    r.nominal_fi,
    r.nominal_zf,
    r.nominal_aqq,
    r.nominal_fdy,
    r.nominal_ifq,
    r.nominal_lqt,
    r.nominal_sdq,
    r.nominal_snk,
    r.nominal_tdy,
    r.nominal_zkt
   FROM analytics.stg_c2_finance_rincian r
UNION ALL
 SELECT r.kantor_id,
    r.instansi,
    r.wajib_ifq,
    r.tunai_fi,
    r.tunai_zf,
    r.tunai_aqq,
    r.tunai_fdy,
    r.tunai_ifq,
    r.tunai_lqt,
    r.tunai_sdq,
    r.tunai_snk,
    r.tunai_tdy,
    r.tunai_zkt,
    r.nominal_fi,
    r.nominal_zf,
    r.nominal_aqq,
    r.nominal_fdy,
    r.nominal_ifq,
    r.nominal_lqt,
    r.nominal_sdq,
    r.nominal_snk,
    r.nominal_tdy,
    r.nominal_zkt
   FROM analytics.stg_c3_finance_rincian r
UNION ALL
 SELECT r.kantor_id,
    r.instansi,
    r.wajib_ifq,
    r.tunai_fi,
    r.tunai_zf,
    r.tunai_aqq,
    r.tunai_fdy,
    r.tunai_ifq,
    r.tunai_lqt,
    r.tunai_sdq,
    r.tunai_snk,
    r.tunai_tdy,
    r.tunai_zkt,
    r.nominal_fi,
    r.nominal_zf,
    r.nominal_aqq,
    r.nominal_fdy,
    r.nominal_ifq,
    r.nominal_lqt,
    r.nominal_sdq,
    r.nominal_snk,
    r.nominal_tdy,
    r.nominal_zkt
   FROM analytics.stg_c4_finance_rincian r;


ALTER VIEW analytics.stg_all_finance_rincian OWNER TO admin;

--
-- TOC entry 260 (class 1259 OID 257594)
-- Name: raw_tester_finance_rekap; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_tester_finance_rekap (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "JENIS" character varying,
    "PERSEN_SETOR" numeric,
    "TOTAL_TANPA_PEMBULATAN" numeric,
    "TOTAL_SETOR_DENGAN_PEMBULATAN" numeric
);


ALTER TABLE public.raw_tester_finance_rekap OWNER TO admin;

--
-- TOC entry 262 (class 1259 OID 257954)
-- Name: stg_tester_finance_rekap; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_tester_finance_rekap AS
 WITH latest_gen AS (
         SELECT max(raw_tester_finance_rekap._airbyte_generation_id) AS last_gen
           FROM public.raw_tester_finance_rekap
        )
 SELECT 'TESTER'::text AS kantor_id,
    r."JENIS" AS jenis,
    r."PERSEN_SETOR" AS persen_setor,
    r."TOTAL_TANPA_PEMBULATAN" AS total_tanpa_pembulatan,
    r."TOTAL_SETOR_DENGAN_PEMBULATAN" AS total_setor_dengan_pembulatan
   FROM (public.raw_tester_finance_rekap r
     JOIN latest_gen lg ON ((r._airbyte_generation_id = lg.last_gen)));


ALTER VIEW analytics.stg_tester_finance_rekap OWNER TO admin;

--
-- TOC entry 261 (class 1259 OID 257600)
-- Name: raw_tester_finance_rincian; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_tester_finance_rincian (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "INSTANSI" character varying,
    "TUNAI_FI" numeric,
    "TUNAI_ZF" numeric,
    "WAJIB_FI" numeric,
    "WAJIB_ZF" numeric,
    "TUNAI_AQQ" numeric,
    "TUNAI_FDY" numeric,
    "TUNAI_IFQ" numeric,
    "TUNAI_LQT" numeric,
    "TUNAI_SDQ" numeric,
    "TUNAI_SNK" numeric,
    "TUNAI_TDY" numeric,
    "TUNAI_ZKT" numeric,
    "WAJIB_AQQ" numeric,
    "WAJIB_FDY" numeric,
    "WAJIB_IFQ" numeric,
    "WAJIB_LQT" numeric,
    "WAJIB_SDQ" numeric,
    "WAJIB_SNK" numeric,
    "WAJIB_TDY" numeric,
    "WAJIB_ZKT" numeric,
    "NOMINAL_FI" numeric,
    "NOMINAL_ZF" numeric,
    "NOMINAL_AQQ" numeric,
    "NOMINAL_FDY" numeric,
    "NOMINAL_IFQ" numeric,
    "NOMINAL_LQT" numeric,
    "NOMINAL_SDQ" numeric,
    "NOMINAL_SNK" numeric,
    "NOMINAL_TDY" numeric,
    "NOMINAL_ZKT" numeric,
    "JUMLAH_WARGA" numeric
);


ALTER TABLE public.raw_tester_finance_rincian OWNER TO admin;

--
-- TOC entry 293 (class 1259 OID 305536)
-- Name: stg_tester_finance_rincian; Type: VIEW; Schema: analytics; Owner: admin
--

CREATE VIEW analytics.stg_tester_finance_rincian AS
 WITH latest_pull AS (
         SELECT max(raw_tester_finance_rincian._airbyte_extracted_at) AS last_extracted_at
           FROM public.raw_tester_finance_rincian
        )
 SELECT 'TESTER'::text AS kantor_id,
    r."INSTANSI" AS instansi,
    NULL::numeric AS wajib_ifq,
    r."TUNAI_FI" AS tunai_fi,
    r."TUNAI_ZF" AS tunai_zf,
    r."TUNAI_AQQ" AS tunai_aqq,
    r."TUNAI_FDY" AS tunai_fdy,
    r."TUNAI_IFQ" AS tunai_ifq,
    r."TUNAI_LQT" AS tunai_lqt,
    r."TUNAI_SDQ" AS tunai_sdq,
    r."TUNAI_SNK" AS tunai_snk,
    r."TUNAI_TDY" AS tunai_tdy,
    r."TUNAI_ZKT" AS tunai_zkt,
    r."NOMINAL_FI" AS nominal_fi,
    r."NOMINAL_ZF" AS nominal_zf,
    r."NOMINAL_AQQ" AS nominal_aqq,
    r."NOMINAL_FDY" AS nominal_fdy,
    r."NOMINAL_IFQ" AS nominal_ifq,
    r."NOMINAL_LQT" AS nominal_lqt,
    r."NOMINAL_SDQ" AS nominal_sdq,
    r."NOMINAL_SNK" AS nominal_snk,
    r."NOMINAL_TDY" AS nominal_tdy,
    r."NOMINAL_ZKT" AS nominal_zkt
   FROM (public.raw_tester_finance_rincian r
     JOIN latest_pull lp ON ((r._airbyte_extracted_at = lp.last_extracted_at)));


ALTER VIEW analytics.stg_tester_finance_rincian OWNER TO admin;

--
-- TOC entry 288 (class 1259 OID 299787)
-- Name: raw_finance_rekap_c5; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rekap_c5 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "JENIS" character varying,
    "DISETOR" numeric,
    "DIKELOLA_KANWIL" numeric,
    "PEMBULATAN_SETOR" numeric,
    "TOTAL_100_PERSEN" numeric
);


ALTER TABLE public.raw_finance_rekap_c5 OWNER TO admin;

--
-- TOC entry 290 (class 1259 OID 299817)
-- Name: raw_finance_rekap_c6; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.raw_finance_rekap_c6 (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "DISETOR" numeric,
    "DIKELOLA_KANWIL" numeric,
    "PEMBULATAN_SETOR" numeric,
    "TOTAL_100_PERSEN" numeric,
    "JENIS" character varying
);


ALTER TABLE public.raw_finance_rekap_c6 OWNER TO admin;

--
-- TOC entry 259 (class 1259 OID 253845)
-- Name: reference_data; Type: VIEW; Schema: public; Owner: admin
--

CREATE VIEW public.reference_data AS
 SELECT code,
    name
   FROM ( VALUES ('JK'::text,'L'::text), ('JK'::text,'P'::text), ('Kelas'::text,'1'::text), ('Kelas'::text,'2'::text), ('Kelas'::text,'3'::text), ('Kanwil'::text,'A1'::text), ('Kanwil'::text,'A2'::text), ('Kanwil'::text,'A3'::text), ('Kanwil'::text,'B1'::text), ('Kanwil'::text,'B2'::text), ('Kanwil'::text,'B3'::text), ('Kanwil'::text,'B4'::text), ('Kanwil'::text,'B5'::text), ('Kanwil'::text,'C1'::text), ('Kanwil'::text,'C2'::text), ('Kanwil'::text,'C3'::text), ('Kanwil'::text,'C4'::text), ('Kanwil'::text,'C5'::text), ('Kanwil'::text,'C6'::text), ('Bidang'::text,'P'::text), ('Bidang'::text,'DP'::text), ('Bidang'::text,'PK'::text), ('Bidang'::text,'HK'::text), ('Bidang'::text,'HM'::text), ('Bidang'::text,'KU'::text), ('Bidang'::text,'KO'::text), ('Status'::text,'Lajang'::text), ('Status'::text,'Nikah'::text), ('Status'::text,'Duda'::text), ('Status'::text,'Janda'::text), ('Tabungan'::text,'Paham'::text), ('Tabungan'::text,'Belum'::text), ('Aktivitas'::text,'A'::text), ('Aktivitas'::text,'AM'::text)) t(code, name);


ALTER VIEW public.reference_data OWNER TO admin;

--
-- TOC entry 264 (class 1259 OID 290245)
-- Name: test_protected_headers; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.test_protected_headers (
    _airbyte_raw_id character varying NOT NULL,
    _airbyte_extracted_at timestamp with time zone NOT NULL,
    _airbyte_meta jsonb NOT NULL,
    _airbyte_generation_id bigint NOT NULL,
    "INSTANSI" character varying,
    "TUNAI_FI" numeric,
    "TUNAI_ZF" numeric,
    "TUNAI_AQQ" numeric,
    "TUNAI_FDY" numeric,
    "TUNAI_IFQ" numeric,
    "TUNAI_LQT" numeric,
    "TUNAI_SDQ" numeric,
    "TUNAI_SNK" numeric,
    "TUNAI_TDY" numeric,
    "TUNAI_ZKT" numeric,
    "NOMINAL_FI" numeric,
    "NOMINAL_ZF" numeric,
    "NOMINAL_AQQ" numeric,
    "NOMINAL_FDY" numeric,
    "NOMINAL_IFQ" numeric,
    "NOMINAL_LQT" numeric,
    "NOMINAL_SDQ" numeric,
    "NOMINAL_SNK" numeric,
    "NOMINAL_TDY" numeric,
    "NOMINAL_ZKT" numeric
);


ALTER TABLE public.test_protected_headers OWNER TO admin;

--
-- TOC entry 3671 (class 1259 OID 22552)
-- Name: idx_extracted_at_raw_a1; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_a1 ON public.raw_a1_temp USING btree (_airbyte_extracted_at);


--
-- TOC entry 3672 (class 1259 OID 22559)
-- Name: idx_extracted_at_raw_a2; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_a2 ON public.raw_a2 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3673 (class 1259 OID 33145)
-- Name: idx_extracted_at_raw_a3; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_a3 ON public.raw_a3 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3674 (class 1259 OID 33164)
-- Name: idx_extracted_at_raw_b1; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_b1 ON public.raw_b1 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3675 (class 1259 OID 33177)
-- Name: idx_extracted_at_raw_b2; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_b2 ON public.raw_b2 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3676 (class 1259 OID 33191)
-- Name: idx_extracted_at_raw_b3; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_b3 ON public.raw_b3 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3677 (class 1259 OID 33204)
-- Name: idx_extracted_at_raw_b4; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_b4 ON public.raw_b4 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3678 (class 1259 OID 33247)
-- Name: idx_extracted_at_raw_b5; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_b5 ON public.raw_b5 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3679 (class 1259 OID 33259)
-- Name: idx_extracted_at_raw_c1; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_c1 ON public.raw_c1 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3680 (class 1259 OID 33279)
-- Name: idx_extracted_at_raw_c2; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_c2 ON public.raw_c2 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3681 (class 1259 OID 33292)
-- Name: idx_extracted_at_raw_c3; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_c3 ON public.raw_c3 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3682 (class 1259 OID 33305)
-- Name: idx_extracted_at_raw_c4; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_c4 ON public.raw_c4 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3683 (class 1259 OID 33312)
-- Name: idx_extracted_at_raw_c5; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_c5 ON public.raw_c5 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3684 (class 1259 OID 33331)
-- Name: idx_extracted_at_raw_c6; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_c6 ON public.raw_c6 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3689 (class 1259 OID 299274)
-- Name: idx_extracted_at_raw_finance_rekap_a1; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rekap_a1 ON public.raw_finance_rekap_a1 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3691 (class 1259 OID 299366)
-- Name: idx_extracted_at_raw_finance_rekap_a2; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rekap_a2 ON public.raw_finance_rekap_a2 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3693 (class 1259 OID 299396)
-- Name: idx_extracted_at_raw_finance_rekap_a3; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rekap_a3 ON public.raw_finance_rekap_a3 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3695 (class 1259 OID 299490)
-- Name: idx_extracted_at_raw_finance_rekap_b1; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rekap_b1 ON public.raw_finance_rekap_b1 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3697 (class 1259 OID 299515)
-- Name: idx_extracted_at_raw_finance_rekap_b2; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rekap_b2 ON public.raw_finance_rekap_b2 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3699 (class 1259 OID 299539)
-- Name: idx_extracted_at_raw_finance_rekap_b3; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rekap_b3 ON public.raw_finance_rekap_b3 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3701 (class 1259 OID 299563)
-- Name: idx_extracted_at_raw_finance_rekap_b4; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rekap_b4 ON public.raw_finance_rekap_b4 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3703 (class 1259 OID 299588)
-- Name: idx_extracted_at_raw_finance_rekap_b5; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rekap_b5 ON public.raw_finance_rekap_b5 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3704 (class 1259 OID 299609)
-- Name: idx_extracted_at_raw_finance_rekap_c1; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rekap_c1 ON public.raw_finance_rekap_c1 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3714 (class 1259 OID 299852)
-- Name: idx_extracted_at_raw_finance_rekap_c2; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rekap_c2 ON public.raw_finance_rekap_c2 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3707 (class 1259 OID 299744)
-- Name: idx_extracted_at_raw_finance_rekap_c3; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rekap_c3 ON public.raw_finance_rekap_c3 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3709 (class 1259 OID 299768)
-- Name: idx_extracted_at_raw_finance_rekap_c4; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rekap_c4 ON public.raw_finance_rekap_c4 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3711 (class 1259 OID 299792)
-- Name: idx_extracted_at_raw_finance_rekap_c5; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rekap_c5 ON public.raw_finance_rekap_c5 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3713 (class 1259 OID 299822)
-- Name: idx_extracted_at_raw_finance_rekap_c6; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rekap_c6 ON public.raw_finance_rekap_c6 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3688 (class 1259 OID 299116)
-- Name: idx_extracted_at_raw_finance_rincian_a1; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rincian_a1 ON public.raw_finance_rincian_a1 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3690 (class 1259 OID 299287)
-- Name: idx_extracted_at_raw_finance_rincian_a2; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rincian_a2 ON public.raw_finance_rincian_a2 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3692 (class 1259 OID 299378)
-- Name: idx_extracted_at_raw_finance_rincian_a3; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rincian_a3 ON public.raw_finance_rincian_a3 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3694 (class 1259 OID 299478)
-- Name: idx_extracted_at_raw_finance_rincian_b1; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rincian_b1 ON public.raw_finance_rincian_b1 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3696 (class 1259 OID 299502)
-- Name: idx_extracted_at_raw_finance_rincian_b2; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rincian_b2 ON public.raw_finance_rincian_b2 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3698 (class 1259 OID 299527)
-- Name: idx_extracted_at_raw_finance_rincian_b3; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rincian_b3 ON public.raw_finance_rincian_b3 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3700 (class 1259 OID 299551)
-- Name: idx_extracted_at_raw_finance_rincian_b4; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rincian_b4 ON public.raw_finance_rincian_b4 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3702 (class 1259 OID 299576)
-- Name: idx_extracted_at_raw_finance_rincian_b5; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rincian_b5 ON public.raw_finance_rincian_b5 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3715 (class 1259 OID 299877)
-- Name: idx_extracted_at_raw_finance_rincian_c1; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rincian_c1 ON public.raw_finance_rincian_c1 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3705 (class 1259 OID 299719)
-- Name: idx_extracted_at_raw_finance_rincian_c2; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rincian_c2 ON public.raw_finance_rincian_c2 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3706 (class 1259 OID 299731)
-- Name: idx_extracted_at_raw_finance_rincian_c3; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rincian_c3 ON public.raw_finance_rincian_c3 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3708 (class 1259 OID 299756)
-- Name: idx_extracted_at_raw_finance_rincian_c4; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rincian_c4 ON public.raw_finance_rincian_c4 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3710 (class 1259 OID 299780)
-- Name: idx_extracted_at_raw_finance_rincian_c5; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rincian_c5 ON public.raw_finance_rincian_c5 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3712 (class 1259 OID 299804)
-- Name: idx_extracted_at_raw_finance_rincian_c6; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_finance_rincian_c6 ON public.raw_finance_rincian_c6 USING btree (_airbyte_extracted_at);


--
-- TOC entry 3685 (class 1259 OID 257599)
-- Name: idx_extracted_at_raw_tester_finance_rekap; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_tester_finance_rekap ON public.raw_tester_finance_rekap USING btree (_airbyte_extracted_at);


--
-- TOC entry 3686 (class 1259 OID 257605)
-- Name: idx_extracted_at_raw_tester_finance_rincian; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_raw_tester_finance_rincian ON public.raw_tester_finance_rincian USING btree (_airbyte_extracted_at);


--
-- TOC entry 3687 (class 1259 OID 290250)
-- Name: idx_extracted_at_test_protected_headers; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX idx_extracted_at_test_protected_headers ON public.test_protected_headers USING btree (_airbyte_extracted_at);


-- Completed on 2026-09-03 16:26:51

--
-- PostgreSQL database dump complete
--

