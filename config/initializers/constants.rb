# human-readable code in which the corresponding japanese characters are arranged one above the other:
#   rubocop:disable Layout/ExtraSpacing
#   rubocop:disable Layout/LineLength
#   rubocop:disable Layout/SpaceBeforeComma

PER_PAGE = 10 # default pagination size
QUOTES_PER_PAGE = 5 # pagination size for quotations

# 150 japanese characters
HIRAGANA            = ["あ", "い", "う", "え", "お",   "か", "き", "く", "け", "こ",   "さ", "し", "す", "せ", "そ",   "た", "ち", "つ", "て", "と",   "な", "に", "ぬ", "ね", "の",   "は", "ひ", "ふ", "へ", "ほ",   "ま", "み", "む", "め", "も",   "や", "", "ゆ", "", "よ",   "ら", "り",  "る", "れ", "ろ",   "わ", "",    "", "", "を"].freeze
HIRAGANA_DAKUTEN    = [""  , "" , ""  , ""  , "" ,   "が", "ぎ", "ぐ", "げ", "ご",   "ざ", "じ", "ず", "ぜ", "ぞ",   "だ", "ぢ", "づ", "で", "ど",     "",   "",  "",   "",  "",    "ば", "び", "ぶ", "べ", "ぼ",    "",  "",   "",   "",   "",     "", "",  "", "",   "",   "",    "",    "",   "",  "",    "",   "",  "",   "", ""].freeze
HIRAGANA_HANDAKUTEN = [""  , "" , ""  , ""  , "" ,     "",  "",   "",   "",  "",     "",   "",  "",   "",   "",    "",   "",  "",   "",   "",     "",  "",   "",   "",  "",    "ぱ", "ぴ", "ぷ", "ぺ", "ぽ",    "",   "",  "",   "",   "",     "", "",  "", "",   "",   "",    "",    "",   "",  "",    "",   "",  "",   "", ""].freeze
KATAKANA            = ["ア", "イ", "ウ", "エ", "オ",   "カ", "キ", "ク", "ケ", "コ",   "サ", "シ", "ス", "セ", "ソ",   "タ", "チ", "ツ", "テ", "ト",   "ナ", "ニ", "ヌ", "ネ", "ノ",   "ハ", "ヒ", "フ", "ヘ", "ホ",   "マ", "ミ", "ム", "メ", "モ",   "ヤ", "", "ユ", "", "ヨ",   "ラ", "リ",  "ル", "レ", "ロ",   "ワ", "ヰ",  "", "ヱ", "ヲ"].freeze
KATAKANA_DAKUTEN    = [""  , "" , "ヴ",  ""  , "" ,   "ガ", "ギ", "グ", "ゲ", "ゴ",   "ザ", "ジ ", "ズ", "ゼ", "ゾ",   "ダ", "ヂ", "ヅ", "デ", "ド",     "",   "",  "",   "",  "",   "バ", "ビ", "ブ", "ベ", "ボ",    "",  "",   "",   "",   "",     "", "",  "", "",   "",   "",    "",    "",   "",  "",    "",   "",  "",   "", ""].freeze
KATAKANA_HANDAKUTEN = [""  , "" , ""  , ""  , "" ,     "",  "",   "",   "",  "",     "",   "",  "",   "",   "",    "",   "",  "",   "",   "",     "",  "",   "",   "",  "",    "パ", "ピ", "プ", "ペ", "ポ",    "",   "",  "",   "",   "",     "", "",  "", "",   "",   "",    "",    "",   "",  "",    "",   "",  "",   "", ""].freeze

# base letters for categories and authors
BASE_LETTERS = {
  de: ("A".."Z").to_a,
  en: ("A".."Z").to_a,
  es: ("A".."Z").to_a,
  ja: HIRAGANA,
  uk: ["А", "Б", "В", "Г", "Ґ", "Д", "Е", "Ж", "З", "И", "І", "К", "Л", "М", "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ю", "Я"]
}.freeze

# for mapping non-base letters
MAP_LETTERS = {
  de: { "Ä" => "A", "Ö" => "O", "Ü" => "U", "ß" => "S", "ẞ" => "S" },
  en: {},
  es: { "Á" => "A", "É" => "E", "Í" => "I", "Ó" => "O", "Ú" => "U", "Ü" => "U", "Ñ" => "N" },
  ja: Hash[(HIRAGANA_DAKUTEN + HIRAGANA_HANDAKUTEN + KATAKANA + KATAKANA_DAKUTEN + KATAKANA_HANDAKUTEN).zip(HIRAGANA * 5)],
  uk: { "Є" => "Е", "Ї" => "І", "Й" => "І" }
}.freeze

# base + non-base
ALL_LETTERS = {
  de: BASE_LETTERS[:de] + MAP_LETTERS[:de].keys,
  en: BASE_LETTERS[:en],
  es: BASE_LETTERS[:es] + MAP_LETTERS[:es].keys,
  ja: BASE_LETTERS[:ja] + MAP_LETTERS[:ja].keys,
  uk: BASE_LETTERS[:uk] + MAP_LETTERS[:uk].keys
}.freeze

# Joomla module help is now on github
QUOTE_JOOMLA_WIKI = {
  de: 'https://github.com/muhme/quote_joomla/wiki/Hilfe',
  en: 'https://github.com/muhme/quote_joomla/wiki',
  es: 'https://github.com/muhme/quote_joomla/wiki/Ayuda',
  ja: 'https://github.com/muhme/quote_joomla/wiki/%E3%83%98%E3%83%AB%E3%83%97', # ヘルプ
  uk: 'https://github.com/muhme/quote_joomla/wiki/%D0%94%D0%BE%D0%BF%D0%BE%D0%BC%D0%BE%D0%B3%D0%B0' # Допомога
}.freeze

if Rails.env == "test"
  AVATARS_DIR = Rails.root.join('public', 'images', 'ta').freeze # test avatars
elsif Rails.env == "development"
  AVATARS_DIR = Rails.root.join('public', 'images', 'da').freeze # development avatars
else
  AVATARS_DIR = Rails.root.join('public', 'images', 'pa').freeze # production avatars
end
# for URL without /quote/public on test/development
# and without /var/www/zitat-service.de/quote/public on production
AVATARS_URL = AVATARS_DIR.to_s.gsub(/.*\/quote\/public/, "").freeze

AVATAR_SIZE = 80 # as 80x80px
