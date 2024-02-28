# app/concerns/reusable_methods.rb
module ReusableMethods
  extend ActiveSupport::Concern

  # use included hook from ActiveSupport::Concern to call extend on the ClassMethods module automatically
  # to define method on class
  included do
    # return mapped letter for base letter or base letter itself
    # '*' returned if the letter is not in the current locale, or if nil
    # e.g. 'A' for 'A' in :en, 'A' for 'Ä' in :de or 'あ' for 'ア' in :ja
    def self.base_letter(letter = nil)
      letter ||= "*"
      locale = I18n.locale

      # Return the letter itself if it's a basic letter
      return letter if BASE_LETTERS[locale]&.include?(letter)

      # Return the corresponding base letter if mapping exist in this locale
      # (e.g. German Umlaut, japanse katakana or spanish accented)
      return MAP_LETTERS[locale][letter] if MAP_LETTERS[locale]&.key?(letter)

      # Return '*' for any other character or if not set
      "*"
    end

    # return given base letter plus all mapped letters as string
    # :de for "a" => "AÄ"
    # :en for "a" => "A"
    # :es for "a" => "AÁ"
    # :ja for "は" => "はばぱハバパ"
    # :uk for "e" => "EЄ"
    def mapped_letters(letter)
      base = letter.upcase
      mapped = MAP_LETTERS[I18n.locale].select { |k, v| v == base }.keys.join
      base + mapped
    end
  end

  def base_letter(letter = nil)
    self.class.base_letter(letter)
  end

  def mapped_letters(letter = nil)
    self.class.mapped_letters(letter)
  end
end
