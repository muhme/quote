class AddCommentsFromCategoriesDescriptions < ActiveRecord::Migration[7.0]
  
  def up
    execute <<-SQL
        INSERT INTO comments (comment, created_at, updated_at, user_id, locale, commentable_type, commentable_id)
        SELECT
            CONCAT('Beschreibung: ', categories.description),
            categories.created_at,
            categories.updated_at,
            categories.user_id,
            'de' AS locale,
            'Category' AS commentable_type,
            categories.id AS commentable_id
        FROM
            categories
        WHERE
            LENGTH(categories.description) > 0;
    SQL

    # change categories "English" and "programming" comments to EN
    execute <<-SQL
        UPDATE comments c
        SET c.locale = 'en',
            c.comment = CONCAT('Description: ', (SELECT description FROM categories WHERE id = c.commentable_id))
        WHERE c.commentable_type = 'Category' AND (c.commentable_id = 264 OR c.commentable_id = 562);
    SQL
        
    execute <<-SQL
        ALTER TABLE categories DROP COLUMN description;
    SQL

  end

  def down
    # You can either leave this method empty or implement a rollback strategy.
  end
end
