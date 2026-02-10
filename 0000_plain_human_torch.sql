CREATE TYPE "public"."user_role" AS ENUM('USER', 'JANITOR', 'MODERATOR', 'ADMIN');--> statement-breakpoint
CREATE TABLE "characters" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text DEFAULT '' NOT NULL,
	"sort_name" text,
	"native_name" text,
	"alternate_names" text[],
	"description" text,
	"primary_image" text,
	"franchise_id" uuid NOT NULL,
	"wikidata_id" text,
	"is_active" boolean DEFAULT true,
	"slug" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "characters_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "companies" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text DEFAULT '' NOT NULL,
	"native_name" text,
	"primary_type" text,
	"founded_year" integer,
	"defunct_year" integer,
	"headquarters_country" varchar(2),
	"company_summary" text,
	"primary_image" text,
	"parent_company_id" uuid,
	"wikidata_id" text,
	"websites" jsonb DEFAULT '{}'::jsonb,
	"is_active" boolean DEFAULT true,
	"slug" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "companies_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "company_roles" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"display_name" text NOT NULL,
	"description" text,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "company_roles_name_unique" UNIQUE("name")
);
--> statement-breakpoint
CREATE TABLE "countries" (
	"code" varchar(2) PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "creator_roles" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"display_name" text NOT NULL,
	"category" text,
	"description" text,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "creator_roles_name_unique" UNIQUE("name")
);
--> statement-breakpoint
CREATE TABLE "creators" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"full_name" text DEFAULT '' NOT NULL,
	"sort_name" text,
	"native_name" text,
	"disambiguation" text,
	"birth_date" date,
	"death_date" date,
	"birth_place" text,
	"nationality" varchar(2),
	"biography" text,
	"primary_image" text,
	"wikidata_id" text,
	"websites" jsonb DEFAULT '{}'::jsonb,
	"details" jsonb DEFAULT '{}'::jsonb,
	"is_active" boolean DEFAULT true,
	"slug" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "creators_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "entries" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"media_type_id" uuid NOT NULL,
	"title" text DEFAULT '' NOT NULL,
	"sort_title" text,
	"alternate_titles" text[],
	"release_date" date,
	"status" text DEFAULT 'released',
	"description" text,
	"nsfw" boolean DEFAULT false,
	"locale_code" varchar(10) NOT NULL,
	"primary_image" text,
	"wikidata_id" text,
	"details" jsonb DEFAULT '{}'::jsonb,
	"is_active" boolean DEFAULT true,
	"slug" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "entries_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "entry_characters" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"entry_id" uuid NOT NULL,
	"character_id" uuid NOT NULL,
	"role" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "entry_companies" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"entry_id" uuid NOT NULL,
	"company_id" uuid NOT NULL,
	"role_id" uuid NOT NULL,
	"credit_order" integer,
	"notes" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "entry_creators" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"entry_id" uuid NOT NULL,
	"creator_id" uuid NOT NULL,
	"role_id" uuid NOT NULL,
	"character_id" uuid,
	"language" varchar(10),
	"credit_order" integer,
	"notes" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "entry_franchises" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"entry_id" uuid NOT NULL,
	"franchise_id" uuid NOT NULL,
	"franchise_release_order" integer,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "entry_genres" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"entry_id" uuid NOT NULL,
	"genre_id" uuid NOT NULL,
	"is_primary" boolean DEFAULT false,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "entry_relationships" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"source_entry_id" uuid NOT NULL,
	"target_entry_id" uuid NOT NULL,
	"relationship_type_id" uuid NOT NULL,
	"notes" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "entry_seasons" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"entry_id" uuid NOT NULL,
	"season_number" integer NOT NULL,
	"title" text,
	"alternate_titles" text[],
	"episode_count" integer,
	"air_date_start" date,
	"air_date_end" date,
	"synopsis" text,
	"primary_image" text,
	"tvdb_id" integer,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "entry_tags" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"entry_id" uuid NOT NULL,
	"tag_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "entry_translations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"entry_id" uuid NOT NULL,
	"locale_code" varchar(10) NOT NULL,
	"translated_title" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "franchises" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"native_name" text,
	"alternate_names" text[],
	"parent_id" uuid,
	"description" text,
	"primary_image" text,
	"wikidata_id" text,
	"websites" jsonb DEFAULT '{}'::jsonb,
	"slug" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "franchises_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "genres" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"display_name" text NOT NULL,
	"parent_id" uuid,
	"media_type_id" uuid,
	"description" text,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "locales" (
	"code" varchar(10) PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"native_name" text,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "media_types" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"display_name" text NOT NULL,
	"description" text,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "media_types_name_unique" UNIQUE("name")
);
--> statement-breakpoint
CREATE TABLE "music_tracks" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"entry_id" uuid NOT NULL,
	"title" text NOT NULL,
	"alternate_titles" text[],
	"duration_seconds" integer,
	"is_instrumental" boolean DEFAULT false,
	"isrc" varchar(12),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "product_categories" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"display_name" text NOT NULL,
	"description" text,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "product_categories_name_unique" UNIQUE("name")
);
--> statement-breakpoint
CREATE TABLE "product_characters" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"product_id" uuid NOT NULL,
	"character_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "product_companies" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"product_id" uuid NOT NULL,
	"company_id" uuid NOT NULL,
	"role_id" uuid NOT NULL,
	"credit_order" integer,
	"notes" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "product_entries" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"product_id" uuid NOT NULL,
	"entry_id" uuid NOT NULL,
	"product_order" integer,
	"notes" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "product_images" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"product_id" uuid NOT NULL,
	"url" text NOT NULL,
	"alt" text,
	"display_order" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "product_listings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"product_id" uuid NOT NULL,
	"retailer_id" uuid NOT NULL,
	"url" text NOT NULL,
	"sku" text,
	"price" numeric(10, 2),
	"currency" text,
	"status" text DEFAULT 'unknown' NOT NULL,
	"last_checked_at" timestamp with time zone,
	"last_price_change_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "product_subcategories" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"display_name" text NOT NULL,
	"category_id" uuid NOT NULL,
	"description" text,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "product_tracks" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"product_id" uuid NOT NULL,
	"track_id" uuid NOT NULL,
	"disc_number" integer DEFAULT 1,
	"track_number" integer NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "product_translations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"product_id" uuid NOT NULL,
	"locale_code" varchar(10) NOT NULL,
	"name" text NOT NULL,
	"description" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "products" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text DEFAULT '' NOT NULL,
	"release_date" date,
	"preorder_date" date,
	"embargo_datetime" timestamp with time zone,
	"upc" varchar(20),
	"msrp" numeric(10, 2),
	"currency" varchar(3) DEFAULT 'USD',
	"category_id" uuid NOT NULL,
	"subcategory_id" uuid,
	"region" varchar(2),
	"nsfw" boolean DEFAULT false NOT NULL,
	"primary_image" text,
	"visibility" text DEFAULT 'public' NOT NULL,
	"verified" boolean DEFAULT false NOT NULL,
	"details" jsonb DEFAULT '{}'::jsonb,
	"is_active" boolean DEFAULT true,
	"slug" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "products_upc_unique" UNIQUE("upc"),
	CONSTRAINT "products_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "relationship_types" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"display_name" text NOT NULL,
	"inverse_name" text,
	"inverse_display_name" text,
	"is_directional" boolean DEFAULT true,
	"description" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "relationship_types_name_unique" UNIQUE("name")
);
--> statement-breakpoint
CREATE TABLE "retailers" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"website" text NOT NULL,
	"logo" text,
	"region" varchar(2),
	"currency" varchar(3) DEFAULT 'USD',
	"parent_company_id" uuid,
	"affiliate_info" jsonb DEFAULT '{}'::jsonb,
	"is_active" boolean DEFAULT true,
	"slug" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "retailers_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "season_episodes" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"season_id" uuid NOT NULL,
	"episode_number" integer NOT NULL,
	"absolute_number" integer,
	"title" text,
	"alternate_titles" text[],
	"air_date" date,
	"runtime_minutes" integer,
	"synopsis" text,
	"primary_image" text,
	"tvdb_id" integer,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "tags" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"display_name" text NOT NULL,
	"category" text,
	"description" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "tags_name_unique" UNIQUE("name")
);
--> statement-breakpoint
CREATE TABLE "track_creators" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"track_id" uuid NOT NULL,
	"creator_id" uuid NOT NULL,
	"role_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "user_profiles" (
	"id" uuid PRIMARY KEY NOT NULL,
	"display_name" text,
	"role" "user_role" DEFAULT 'USER' NOT NULL,
	"show_nsfw" boolean DEFAULT false NOT NULL,
	"dark_mode" boolean DEFAULT false NOT NULL,
	"locale_code" varchar(10) DEFAULT 'en',
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "characters" ADD CONSTRAINT "characters_franchise_id_franchises_id_fk" FOREIGN KEY ("franchise_id") REFERENCES "public"."franchises"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "companies" ADD CONSTRAINT "companies_headquarters_country_countries_code_fk" FOREIGN KEY ("headquarters_country") REFERENCES "public"."countries"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "companies" ADD CONSTRAINT "companies_parent_company_id_companies_id_fk" FOREIGN KEY ("parent_company_id") REFERENCES "public"."companies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "creators" ADD CONSTRAINT "creators_nationality_countries_code_fk" FOREIGN KEY ("nationality") REFERENCES "public"."countries"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entries" ADD CONSTRAINT "entries_media_type_id_media_types_id_fk" FOREIGN KEY ("media_type_id") REFERENCES "public"."media_types"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entries" ADD CONSTRAINT "entries_locale_code_locales_code_fk" FOREIGN KEY ("locale_code") REFERENCES "public"."locales"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_characters" ADD CONSTRAINT "entry_characters_entry_id_entries_id_fk" FOREIGN KEY ("entry_id") REFERENCES "public"."entries"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_characters" ADD CONSTRAINT "entry_characters_character_id_characters_id_fk" FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_companies" ADD CONSTRAINT "entry_companies_entry_id_entries_id_fk" FOREIGN KEY ("entry_id") REFERENCES "public"."entries"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_companies" ADD CONSTRAINT "entry_companies_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_companies" ADD CONSTRAINT "entry_companies_role_id_company_roles_id_fk" FOREIGN KEY ("role_id") REFERENCES "public"."company_roles"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_creators" ADD CONSTRAINT "entry_creators_entry_id_entries_id_fk" FOREIGN KEY ("entry_id") REFERENCES "public"."entries"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_creators" ADD CONSTRAINT "entry_creators_creator_id_creators_id_fk" FOREIGN KEY ("creator_id") REFERENCES "public"."creators"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_creators" ADD CONSTRAINT "entry_creators_role_id_creator_roles_id_fk" FOREIGN KEY ("role_id") REFERENCES "public"."creator_roles"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_creators" ADD CONSTRAINT "entry_creators_character_id_characters_id_fk" FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_franchises" ADD CONSTRAINT "entry_franchises_entry_id_entries_id_fk" FOREIGN KEY ("entry_id") REFERENCES "public"."entries"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_franchises" ADD CONSTRAINT "entry_franchises_franchise_id_franchises_id_fk" FOREIGN KEY ("franchise_id") REFERENCES "public"."franchises"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_genres" ADD CONSTRAINT "entry_genres_entry_id_entries_id_fk" FOREIGN KEY ("entry_id") REFERENCES "public"."entries"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_genres" ADD CONSTRAINT "entry_genres_genre_id_genres_id_fk" FOREIGN KEY ("genre_id") REFERENCES "public"."genres"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_relationships" ADD CONSTRAINT "entry_relationships_source_entry_id_entries_id_fk" FOREIGN KEY ("source_entry_id") REFERENCES "public"."entries"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_relationships" ADD CONSTRAINT "entry_relationships_target_entry_id_entries_id_fk" FOREIGN KEY ("target_entry_id") REFERENCES "public"."entries"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_relationships" ADD CONSTRAINT "entry_relationships_relationship_type_id_relationship_types_id_fk" FOREIGN KEY ("relationship_type_id") REFERENCES "public"."relationship_types"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_seasons" ADD CONSTRAINT "entry_seasons_entry_id_entries_id_fk" FOREIGN KEY ("entry_id") REFERENCES "public"."entries"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_tags" ADD CONSTRAINT "entry_tags_entry_id_entries_id_fk" FOREIGN KEY ("entry_id") REFERENCES "public"."entries"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_tags" ADD CONSTRAINT "entry_tags_tag_id_tags_id_fk" FOREIGN KEY ("tag_id") REFERENCES "public"."tags"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_translations" ADD CONSTRAINT "entry_translations_entry_id_entries_id_fk" FOREIGN KEY ("entry_id") REFERENCES "public"."entries"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "entry_translations" ADD CONSTRAINT "entry_translations_locale_code_locales_code_fk" FOREIGN KEY ("locale_code") REFERENCES "public"."locales"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "franchises" ADD CONSTRAINT "franchises_parent_id_franchises_id_fk" FOREIGN KEY ("parent_id") REFERENCES "public"."franchises"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "genres" ADD CONSTRAINT "genres_parent_id_genres_id_fk" FOREIGN KEY ("parent_id") REFERENCES "public"."genres"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "genres" ADD CONSTRAINT "genres_media_type_id_media_types_id_fk" FOREIGN KEY ("media_type_id") REFERENCES "public"."media_types"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "music_tracks" ADD CONSTRAINT "music_tracks_entry_id_entries_id_fk" FOREIGN KEY ("entry_id") REFERENCES "public"."entries"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_characters" ADD CONSTRAINT "product_characters_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_characters" ADD CONSTRAINT "product_characters_character_id_characters_id_fk" FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_companies" ADD CONSTRAINT "product_companies_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_companies" ADD CONSTRAINT "product_companies_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_companies" ADD CONSTRAINT "product_companies_role_id_company_roles_id_fk" FOREIGN KEY ("role_id") REFERENCES "public"."company_roles"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_entries" ADD CONSTRAINT "product_entries_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_entries" ADD CONSTRAINT "product_entries_entry_id_entries_id_fk" FOREIGN KEY ("entry_id") REFERENCES "public"."entries"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_images" ADD CONSTRAINT "product_images_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_listings" ADD CONSTRAINT "product_listings_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_listings" ADD CONSTRAINT "product_listings_retailer_id_retailers_id_fk" FOREIGN KEY ("retailer_id") REFERENCES "public"."retailers"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_subcategories" ADD CONSTRAINT "product_subcategories_category_id_product_categories_id_fk" FOREIGN KEY ("category_id") REFERENCES "public"."product_categories"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_tracks" ADD CONSTRAINT "product_tracks_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_tracks" ADD CONSTRAINT "product_tracks_track_id_music_tracks_id_fk" FOREIGN KEY ("track_id") REFERENCES "public"."music_tracks"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_translations" ADD CONSTRAINT "product_translations_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "product_translations" ADD CONSTRAINT "product_translations_locale_code_locales_code_fk" FOREIGN KEY ("locale_code") REFERENCES "public"."locales"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "products" ADD CONSTRAINT "products_category_id_product_categories_id_fk" FOREIGN KEY ("category_id") REFERENCES "public"."product_categories"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "products" ADD CONSTRAINT "products_subcategory_id_product_subcategories_id_fk" FOREIGN KEY ("subcategory_id") REFERENCES "public"."product_subcategories"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "products" ADD CONSTRAINT "products_region_countries_code_fk" FOREIGN KEY ("region") REFERENCES "public"."countries"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "retailers" ADD CONSTRAINT "retailers_region_countries_code_fk" FOREIGN KEY ("region") REFERENCES "public"."countries"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "retailers" ADD CONSTRAINT "retailers_parent_company_id_companies_id_fk" FOREIGN KEY ("parent_company_id") REFERENCES "public"."companies"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "season_episodes" ADD CONSTRAINT "season_episodes_season_id_entry_seasons_id_fk" FOREIGN KEY ("season_id") REFERENCES "public"."entry_seasons"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "track_creators" ADD CONSTRAINT "track_creators_track_id_music_tracks_id_fk" FOREIGN KEY ("track_id") REFERENCES "public"."music_tracks"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "track_creators" ADD CONSTRAINT "track_creators_creator_id_creators_id_fk" FOREIGN KEY ("creator_id") REFERENCES "public"."creators"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "track_creators" ADD CONSTRAINT "track_creators_role_id_creator_roles_id_fk" FOREIGN KEY ("role_id") REFERENCES "public"."creator_roles"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_profiles" ADD CONSTRAINT "user_profiles_locale_code_locales_code_fk" FOREIGN KEY ("locale_code") REFERENCES "public"."locales"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "characters_franchise_idx" ON "characters" USING btree ("franchise_id");--> statement-breakpoint
CREATE INDEX "characters_name_idx" ON "characters" USING btree ("name");--> statement-breakpoint
CREATE INDEX "companies_name_idx" ON "companies" USING btree ("name");--> statement-breakpoint
CREATE INDEX "creators_full_name_idx" ON "creators" USING btree ("full_name");--> statement-breakpoint
CREATE INDEX "entries_media_type_idx" ON "entries" USING btree ("media_type_id");--> statement-breakpoint
CREATE INDEX "entries_title_idx" ON "entries" USING btree ("title");--> statement-breakpoint
CREATE INDEX "entries_release_date_idx" ON "entries" USING btree ("release_date");--> statement-breakpoint
CREATE UNIQUE INDEX "entry_characters_entry_character" ON "entry_characters" USING btree ("entry_id","character_id");--> statement-breakpoint
CREATE INDEX "entry_characters_entry_idx" ON "entry_characters" USING btree ("entry_id");--> statement-breakpoint
CREATE INDEX "entry_characters_character_idx" ON "entry_characters" USING btree ("character_id");--> statement-breakpoint
CREATE UNIQUE INDEX "entry_companies_unique" ON "entry_companies" USING btree ("entry_id","company_id","role_id");--> statement-breakpoint
CREATE INDEX "entry_companies_entry_idx" ON "entry_companies" USING btree ("entry_id");--> statement-breakpoint
CREATE INDEX "entry_companies_company_idx" ON "entry_companies" USING btree ("company_id");--> statement-breakpoint
CREATE UNIQUE INDEX "entry_creators_unique" ON "entry_creators" USING btree ("entry_id","creator_id","role_id","character_id","language");--> statement-breakpoint
CREATE INDEX "entry_creators_entry_idx" ON "entry_creators" USING btree ("entry_id");--> statement-breakpoint
CREATE INDEX "entry_creators_creator_idx" ON "entry_creators" USING btree ("creator_id");--> statement-breakpoint
CREATE UNIQUE INDEX "entry_franchises_entry_franchise" ON "entry_franchises" USING btree ("entry_id","franchise_id");--> statement-breakpoint
CREATE INDEX "entry_franchises_entry_idx" ON "entry_franchises" USING btree ("entry_id");--> statement-breakpoint
CREATE INDEX "entry_franchises_franchise_idx" ON "entry_franchises" USING btree ("franchise_id");--> statement-breakpoint
CREATE UNIQUE INDEX "entry_genres_entry_genre" ON "entry_genres" USING btree ("entry_id","genre_id");--> statement-breakpoint
CREATE INDEX "entry_genres_entry_idx" ON "entry_genres" USING btree ("entry_id");--> statement-breakpoint
CREATE UNIQUE INDEX "entry_relationships_source_target_type" ON "entry_relationships" USING btree ("source_entry_id","target_entry_id","relationship_type_id");--> statement-breakpoint
CREATE INDEX "entry_relationships_source_idx" ON "entry_relationships" USING btree ("source_entry_id");--> statement-breakpoint
CREATE INDEX "entry_relationships_target_idx" ON "entry_relationships" USING btree ("target_entry_id");--> statement-breakpoint
CREATE UNIQUE INDEX "entry_seasons_entry_season_number" ON "entry_seasons" USING btree ("entry_id","season_number");--> statement-breakpoint
CREATE INDEX "entry_seasons_entry_idx" ON "entry_seasons" USING btree ("entry_id");--> statement-breakpoint
CREATE INDEX "entry_seasons_tvdb_idx" ON "entry_seasons" USING btree ("tvdb_id");--> statement-breakpoint
CREATE UNIQUE INDEX "entry_tags_entry_tag" ON "entry_tags" USING btree ("entry_id","tag_id");--> statement-breakpoint
CREATE INDEX "entry_tags_entry_idx" ON "entry_tags" USING btree ("entry_id");--> statement-breakpoint
CREATE UNIQUE INDEX "entry_translations_entry_locale" ON "entry_translations" USING btree ("entry_id","locale_code");--> statement-breakpoint
CREATE INDEX "entry_translations_entry_idx" ON "entry_translations" USING btree ("entry_id");--> statement-breakpoint
CREATE INDEX "franchises_name_idx" ON "franchises" USING btree ("name");--> statement-breakpoint
CREATE INDEX "franchises_parent_idx" ON "franchises" USING btree ("parent_id");--> statement-breakpoint
CREATE UNIQUE INDEX "genres_name_media_type_idx" ON "genres" USING btree ("name","media_type_id");--> statement-breakpoint
CREATE INDEX "music_tracks_entry_idx" ON "music_tracks" USING btree ("entry_id");--> statement-breakpoint
CREATE UNIQUE INDEX "product_characters_product_character" ON "product_characters" USING btree ("product_id","character_id");--> statement-breakpoint
CREATE INDEX "product_characters_product_idx" ON "product_characters" USING btree ("product_id");--> statement-breakpoint
CREATE INDEX "product_characters_character_idx" ON "product_characters" USING btree ("character_id");--> statement-breakpoint
CREATE UNIQUE INDEX "product_companies_unique" ON "product_companies" USING btree ("product_id","company_id","role_id");--> statement-breakpoint
CREATE INDEX "product_companies_product_idx" ON "product_companies" USING btree ("product_id");--> statement-breakpoint
CREATE INDEX "product_companies_company_idx" ON "product_companies" USING btree ("company_id");--> statement-breakpoint
CREATE UNIQUE INDEX "product_entries_product_entry" ON "product_entries" USING btree ("product_id","entry_id");--> statement-breakpoint
CREATE INDEX "product_entries_product_idx" ON "product_entries" USING btree ("product_id");--> statement-breakpoint
CREATE INDEX "product_entries_entry_idx" ON "product_entries" USING btree ("entry_id");--> statement-breakpoint
CREATE INDEX "product_images_product_idx" ON "product_images" USING btree ("product_id");--> statement-breakpoint
CREATE UNIQUE INDEX "product_listings_product_retailer" ON "product_listings" USING btree ("product_id","retailer_id");--> statement-breakpoint
CREATE INDEX "product_listings_product_idx" ON "product_listings" USING btree ("product_id");--> statement-breakpoint
CREATE INDEX "product_listings_retailer_idx" ON "product_listings" USING btree ("retailer_id");--> statement-breakpoint
CREATE INDEX "product_listings_status_idx" ON "product_listings" USING btree ("status");--> statement-breakpoint
CREATE INDEX "product_listings_last_checked_idx" ON "product_listings" USING btree ("last_checked_at");--> statement-breakpoint
CREATE UNIQUE INDEX "product_subcategories_category_name" ON "product_subcategories" USING btree ("category_id","name");--> statement-breakpoint
CREATE UNIQUE INDEX "product_tracks_product_disc_track" ON "product_tracks" USING btree ("product_id","disc_number","track_number");--> statement-breakpoint
CREATE UNIQUE INDEX "product_tracks_product_track" ON "product_tracks" USING btree ("product_id","track_id");--> statement-breakpoint
CREATE UNIQUE INDEX "product_translations_product_locale" ON "product_translations" USING btree ("product_id","locale_code");--> statement-breakpoint
CREATE INDEX "product_translations_product_idx" ON "product_translations" USING btree ("product_id");--> statement-breakpoint
CREATE INDEX "product_translations_name_idx" ON "product_translations" USING btree ("name");--> statement-breakpoint
CREATE INDEX "products_category_idx" ON "products" USING btree ("category_id");--> statement-breakpoint
CREATE INDEX "products_subcategory_idx" ON "products" USING btree ("subcategory_id");--> statement-breakpoint
CREATE INDEX "products_release_date_idx" ON "products" USING btree ("release_date");--> statement-breakpoint
CREATE INDEX "products_visibility_idx" ON "products" USING btree ("visibility");--> statement-breakpoint
CREATE INDEX "products_name_idx" ON "products" USING btree ("name");--> statement-breakpoint
CREATE UNIQUE INDEX "season_episodes_season_episode_number" ON "season_episodes" USING btree ("season_id","episode_number");--> statement-breakpoint
CREATE INDEX "season_episodes_season_idx" ON "season_episodes" USING btree ("season_id");--> statement-breakpoint
CREATE INDEX "season_episodes_tvdb_idx" ON "season_episodes" USING btree ("tvdb_id");--> statement-breakpoint
CREATE UNIQUE INDEX "track_creators_track_creator_role" ON "track_creators" USING btree ("track_id","creator_id","role_id");--> statement-breakpoint

-- ============================================================================
-- SUPABASE: Function & Trigger (not managed by Drizzle)
-- ============================================================================

-- Auto-create user_profiles row when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
  BEGIN
    INSERT INTO public.user_profiles (id, role, show_nsfw, created_at, updated_at)
    VALUES (NEW.id, 'USER', false, NOW(), NOW());
    RETURN NEW;
  END;
$function$;

-- Attach trigger to auth.users (Supabase auth schema)
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();