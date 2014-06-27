require_relative '../test_helper'

include Warden::Test::Helpers

feature "Exports" do

  let(:private_user)       { FactoryGirl.create :private_user }
  let(:legal_entity)       { FactoryGirl.create :legal_entity_with_fixture_address, :paypal_data }
  let(:legal_entity_buyer) { FactoryGirl.create :legal_entity_with_fixture_address, :email => "hans@dampf.de" }

  scenario 'private user is on his profile and should not see export link' do
    login_as private_user
    visit user_path(private_user)
    page.wont_have_link I18n.t('articles.export.inactive')
  end

  scenario "legal entity exports his inactive and active articles" do
    login_as legal_entity
    visit new_mass_upload_path

    # first upload some articles for comparison
    attach_file('mass_upload_file', 'test/fixtures/mass_upload_correct_upload_export_test.csv')
    click_button I18n.t('mass_uploads.labels.upload_article')

    visit user_path(legal_entity)

    click_link I18n.t('articles.export.inactive')

    page.source.must_equal IO.read('test/fixtures/mass_upload_export.csv', encoding: 'ascii-8bit') #page source returns ascii-8 bit

    visit user_path(legal_entity)
    # activate all articles
    click_link I18n.t('mass_uploads.labels.show_report')
    click_button I18n.t('mass_uploads.labels.mass_activate_articles')

    visit user_path(legal_entity)
    click_link I18n.t('articles.export.active')

    page.source.must_equal IO.read('test/fixtures/mass_upload_export.csv', encoding: 'ascii-8bit')
  end

  scenario "legal entity exporting sold articles and other legal entity exporting its bought articles" do
    # get some articles
    login_as legal_entity
    visit new_mass_upload_path
    attach_file('mass_upload_file', 'test/fixtures/mass_upload_multiple.csv')
    click_button I18n.t('mass_uploads.labels.upload_article')
    visit mass_upload_path(MassUpload.last)
    click_button I18n.t('mass_uploads.labels.mass_activate_articles')

    # sell them
    @transaction1 = FactoryGirl.create :single_transaction, :sold,
                                      article: legal_entity.articles.last,
                                      buyer: legal_entity_buyer,
                                      shipping_address: legal_entity_buyer.standard_address,
                                      billing_address: legal_entity_buyer.standard_address,
                                      sold_at: "2013-12-03 17:50:15"

    legal_entity.articles.each { |article| article.update_attribute(:state, 'sold') }
    visit user_path(legal_entity)
    click_link I18n.t('articles.export.sold')
    page.source.must_equal  IO.read('test/fixtures/mass_upload_correct_export_test_sold.csv', encoding: 'ascii-8bit')


    logout(:user)
    login_as legal_entity_buyer
    visit user_path(legal_entity_buyer)
    click_link I18n.t('articles.export.bought')

    page.source.must_equal  IO.read('test/fixtures/mass_upload_export_bought.csv', encoding: 'ascii-8bit')

  end

  scenario 'export an article with a social producer questionnaire' do
    login_as legal_entity
    visit new_mass_upload_path
    attach_file('mass_upload_file', 'test/fixtures/export_upload_social_producer.csv')
    click_button I18n.t('mass_uploads.labels.upload_article')
    click_link I18n.t('articles.export.inactive')

    page.source.must_equal  IO.read('test/fixtures/export_social_producer.csv', encoding: 'ascii-8bit')

  end

  scenario 'user exports erroneous articles' do
    login_as legal_entity
    visit new_mass_upload_path
    attach_file('mass_upload_file', 'test/fixtures/mass_upload_wrong_article.csv')
    click_button I18n.t('mass_uploads.labels.upload_article')
    visit mass_upload_path(MassUpload.last)
    click_link "Fehlerhafte Artikel exportieren"
    page.source.must_equal IO.read('test/fixtures/mass_upload_wrong_article.csv')

  end
end
