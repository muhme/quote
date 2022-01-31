# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_01_29_164141) do

  create_table "active_storage_attachments", charset: "utf8mb4", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: 6, null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "authors", charset: "utf8mb3", force: :cascade do |t|
    t.string "name", limit: 64
    t.string "firstname", limit: 64
    t.string "description"
    t.string "link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "public", default: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_authors_on_user_id"
  end

  create_table "categories", charset: "utf8mb3", force: :cascade do |t|
    t.string "category", limit: 64, null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "public", default: false
    t.bigint "user_id"
    t.index ["public"], name: "index_categories_on_public"
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "categories_quotations", id: false, charset: "utf8mb3", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.bigint "quotation_id", null: false
    t.index ["category_id", "quotation_id"], name: "index_categories_quotations_on_category_id_and_quotation_id"
    t.index ["quotation_id", "category_id"], name: "index_categories_quotations_on_quotation_id_and_category_id"
  end

  create_table "quotations", charset: "utf8mb3", force: :cascade do |t|
    t.string "quotation", limit: 512, null: false
    t.string "source"
    t.string "source_link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "public", default: false
    t.bigint "user_id"
    t.bigint "author_id"
    t.index ["author_id"], name: "index_quotations_on_author_id"
    t.index ["public"], name: "index_quotations_on_public"
    t.index ["user_id"], name: "index_quotations_on_user_id"
  end

  create_table "users", charset: "utf8mb3", force: :cascade do |t|
    t.string "email", limit: 64
    t.string "crypted_password"
    t.string "password_salt"
    t.string "persistence_token"
    t.boolean "active", default: false
    t.boolean "approved", default: false
    t.boolean "confirmed", default: false
    t.datetime "last_login_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "login", limit: 32, null: false
    t.boolean "admin", default: false
    t.string "perishable_token", default: "", null: false
    t.index ["perishable_token"], name: "index_users_on_perishable_token"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "authors", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "quotations", "authors"
  add_foreign_key "quotations", "users"
end
