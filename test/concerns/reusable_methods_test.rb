# test/concerns/reusable_methods_test.rb
require 'test_helper'

class ReusableMethodsTest < ActiveSupport::TestCase
  class DummyClass
    include ReusableMethods
  end

  def setup
    @dummy = DummyClass.new
  end

  test 'base_letter with :de locale' do
    I18n.locale = :de
    assert_equal 'A', @dummy.base_letter('Ä')
    assert_equal '*', @dummy.base_letter('Я')
  end
  test 'base_letter with :en locale' do
    I18n.locale = :en
    assert_equal 'A', @dummy.base_letter('A')
    assert_equal '*', @dummy.base_letter('Ä')
  end
  test 'base_letter with :es locale' do
    I18n.locale = :es
    assert_equal 'I', @dummy.base_letter('Í')
    assert_equal '*', @dummy.base_letter('42')
  end
  test 'base_letter with :ja locale' do
    I18n.locale = :ja
    assert_equal 'あ', @dummy.base_letter('ア')
    assert_equal 'ほ', @dummy.base_letter('ポ')
  end
  test 'base_letter with :uk locale' do
    I18n.locale = :uk
    assert_equal 'Е', @dummy.base_letter('Є')
    assert_equal 'Б', @dummy.base_letter('Б')
  end

  test 'mapped_letters with :de locale' do
    I18n.locale = :de
    assert_equal 'AÄ', @dummy.mapped_letters('a')
  end
  test 'mapped_letters with :en locale' do
    I18n.locale = :en
    assert_equal 'A', @dummy.mapped_letters('a')
  end
  test 'mapped_letters with :es locale' do
    I18n.locale = :es
    assert_equal 'AÁ', @dummy.mapped_letters('a')
  end
  test 'mapped_letters with :ja locale' do
    I18n.locale = :ja
    assert_equal 'はばぱハバパ', @dummy.mapped_letters('は')
  end
  test 'mapped_letters with :uk locale' do
    I18n.locale = :uk
    assert_equal 'A', @dummy.mapped_letters('a')
  end
end
