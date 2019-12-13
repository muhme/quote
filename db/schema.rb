# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_12_11_162527) do

  create_table "authors", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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

  create_table "categories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "category", limit: 64, null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "public", default: false
    t.bigint "user_id"
    t.index ["public"], name: "index_categories_on_public"
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "categories_quotations", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.bigint "quotation_id", null: false
    t.index ["category_id", "quotation_id"], name: "index_categories_quotations_on_category_id_and_quotation_id"
    t.index ["quotation_id", "category_id"], name: "index_categories_quotations_on_quotation_id_and_category_id"
  end

  create_table "quotations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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

  add_foreign_key "authors", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "quotations", "authors"
  add_foreign_key "quotations", "users"
end
