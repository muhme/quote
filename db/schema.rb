# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 0) do

  create_table "authors", :force => true do |t|
    t.string   "name",        :limit => 64, :default => "",    :null => false
    t.string   "firstname",   :limit => 64
    t.string   "description"
    t.string   "link"
    t.integer  "user_id",     :limit => 11, :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "public",                    :default => false
  end

  add_index "authors", ["user_id"], :name => "fk_a_user"

  create_table "categories", :force => true do |t|
    t.string   "category",    :limit => 64, :default => "",    :null => false
    t.string   "description"
    t.integer  "user_id",     :limit => 11, :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "public",                    :default => false
  end

  add_index "categories", ["category"], :name => "category", :unique => true
  add_index "categories", ["user_id"], :name => "fk_c_user"

  create_table "categories_quotations", :id => false, :force => true do |t|
    t.integer "quotation_id", :limit => 11, :default => 0, :null => false
    t.integer "category_id",  :limit => 11, :default => 0, :null => false
  end

  add_index "categories_quotations", ["category_id"], :name => "fk_category"

  create_table "quotations", :force => true do |t|
    t.string   "quotation",   :limit => 512, :default => "",    :null => false
    t.string   "source"
    t.string   "source_link"
    t.integer  "author_id",   :limit => 11,  :default => 0
    t.integer  "user_id",     :limit => 11,  :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "public",                     :default => false
  end

  add_index "quotations", ["user_id"], :name => "fk_q_user"
  add_index "quotations", ["author_id"], :name => "fk_author"

  create_table "users", :force => true do |t|
    t.boolean  "admin",                                   :default => false
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
  end

end
