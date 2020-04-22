#   Copyright (c) 2012-2017, Fairmondo eG.  This file is
#   licensed under the GNU Affero General Public License version 3 or later.
#   See the COPYRIGHT file for details.

module ArticlesHelper
  # Conditions
  def condition_label article
    condition_text = t("enumerize.article.condition.#{article.condition}")
    "<span class=\"Tag Tag--gray\">#{condition_text}</span>".html_safe
  end

  # Build title string
  def index_title_for search_cache
    attribute_list = ::HumanLanguageList.new
    attribute_list << t('article.show.title.new') if search_cache.condition == 'new'
    attribute_list << t('article.show.title.old') if search_cache.condition == 'old'
    attribute_list << t('article.show.title.fair') if search_cache.fair
    attribute_list << t('article.show.title.ecologic') if search_cache.ecologic
    attribute_list << t('article.show.title.small_and_precious') if search_cache.small_and_precious

    output = attribute_list.concatenate.capitalize + ' '
    output << search_cache.searched_category.name + ' ' if search_cache.searched_category

    output << t('article.show.title.article')
  end

  def breadcrumbs_for category
    output = ''
    category.self_and_ancestors.each do |c|
      last = c == category
      output << '<span>'
      output << "<a href='#{category_path(c)}' class='#{(last ? 'last' : nil)}'>"
      output << c.name
      output << '</a>'
      output << '</span>'
      output << ' > ' unless last
    end

    output
  end

  def default_organisation_from organisation_list
    begin
      organisation = default_form_value('friendly_percent_organisation', resource)
      default_organisation = organisation_list.select { |o| o.nickname == organisation.nickname }
      default_organisation[0] ? default_organisation[0].id : nil
    rescue
      nil
    end
  end

  # Returns true if the basic price should be shown to users
  #
  # @return Boolean
  def show_basic_price_for? article
    article.belongs_to_legal_entity? && article.basic_price_amount && article.basic_price && article.basic_price > 0
  end

  # Returns true if the friendly_percent should be shown
  #
  # @return Boolean
  def show_friendly_percent_for? article
    article.friendly_percent && article.friendly_percent > 0 && article.friendly_percent_organisation_nickname && !article.seller_ngo
  end

  def show_fair_percent_for? article
    # for german book price agreement
    # we can't be sure if the book is german
    # so we dont show fair percent on all new books
    # book category is written in exceptions.yml

    # disable fair percent
    # article.belongs_to_legal_entity? && !article.could_be_book_price_agreement? && article.friendly_percent != 100
    false
  end

  def available_transport method
    resource.send("transport_#{ method }")
  end

  def transport_string_for method
    if %w(type1 type2).include?(method)
      resource.send("transport_#{method}_provider")
    else
      t("formtastic.labels.article.transport_#{method}")
    end
  end

  def cost_info_for method
    if free_or_not_for? method
      '(kostenfrei)'
    else
      "zzgl. #{ humanized_money_with_symbol(resource.send("transport_#{ method }_price"))}"
    end
  end

  def additional_info_for method
    if method == 'pickup'
      "(PLZ: #{ resource.seller.standard_address_zip })"
    elsif method == 'bike_courier'
      'bar bei Lieferung (z.Z. nur im Berliner Innenstadtbereich verfügbar)'
    end
  end

  def free_or_not_for? method
    resource.seller.free_transport_available &&
      resource.seller_free_transport_at_price <= resource.price &&
      !resource.transport_bike_courier ||
      !resource.respond_to?("transport_#{ method }_price")
  end

  # def export_time_ranges
  #  # specify time range in months
  #  ['all', '1', '3', '6', '12']
  # end
end
