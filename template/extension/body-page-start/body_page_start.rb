# frozen_string_literal: true

require 'asciidoctor-pdf'
require 'set'

module BodyPageStart
  START_ID_ATTRS = %w[body-page-start-id body-page-numbering-start-id].freeze
  COVER_PAGES_ATTR = 'body-page-start-cover-pages'
  PAGE_NUMBER_ATTR = 'body-page-number'

  def apply_subs_discretely doc, value, opts = {}
    return super unless value.include? "{#{PAGE_NUMBER_ATTR}}"

    previous_value = doc.attr PAGE_NUMBER_ATTR
    if (page_label = body_page_start_label doc, page_number)
      doc.set_attr PAGE_NUMBER_ATTR, page_label
    elsif (fallback_label = doc.attr 'page-number')
      doc.set_attr PAGE_NUMBER_ATTR, fallback_label
    else
      doc.remove_attr PAGE_NUMBER_ATTR
    end
    super
  ensure
    if value&.include? "{#{PAGE_NUMBER_ATTR}}"
      previous_value ? (doc.set_attr PAGE_NUMBER_ATTR, previous_value) : (doc.remove_attr PAGE_NUMBER_ATTR)
    end
  end

  def ink_toc doc, num_levels, toc_page_number, start_cursor, num_front_matter_pages = 0
    if !scratch? && (start_page = body_page_start_page doc)
      num_front_matter_pages = start_page - 1
    end
    super
  end

  def add_outline doc, num_levels, toc_page_nums, num_front_matter_pages, has_front_cover
    if (start_page = body_page_start_page doc)
      super doc, num_levels, toc_page_nums, (start_page - 1), has_front_cover
      body_page_start_install_page_labels doc, start_page
    else
      super
    end
  end

  private

  def body_page_start_label doc, physical_page_number
    return unless (start_page = body_page_start_page doc)

    cover_pages = body_page_start_cover_pages doc
    if physical_page_number < start_page
      front_page_number = physical_page_number - cover_pages
      front_page_number.positive? ? (::Asciidoctor::PDF::RomanNumeral.new front_page_number, :lower).to_s : nil
    else
      (physical_page_number - start_page + 1).to_s
    end
  end

  def body_page_start_page doc
    return @body_page_start_page if @body_page_start_page

    start_id = START_ID_ATTRS.map {|attr_name| doc.attr attr_name }.compact.find {|value| !value.empty? }
    return unless start_id

    start_id = start_id.delete_prefix '#'
    target = (doc.catalog[:ids][start_id] if doc.catalog[:ids]) ||
      (doc.find_by {|node| node.respond_to?(:id) && node.id == start_id }.first)
    unless target
      body_page_start_warn_once %(could not find body page start id `#{start_id}`)
      return
    end

    unless (start_page = target.attr 'pdf-page-start')
      body_page_start_warn_once %(body page start id `#{start_id}` does not have a PDF page yet)
      return
    end

    @body_page_start_page = start_page.to_i
  end

  def body_page_start_cover_pages doc
    if (cover_pages = doc.attr COVER_PAGES_ATTR)
      cover_pages.to_i
    elsif doc.doctype == 'book' || (doc.attr? 'title-page')
      1
    else
      0
    end
  end

  def body_page_start_install_page_labels doc, start_page
    cover_pages = body_page_start_cover_pages doc
    pagenum_labels = {}

    cover_pages.times do |idx|
      pagenum_labels[idx] = { P: (::PDF::Core::LiteralString.new '') }
    end

    front_label_count = [start_page - 1 - cover_pages, 0].max
    front_label_count.times do |idx|
      pagenum_labels[cover_pages + idx] = {
        P: (::PDF::Core::LiteralString.new((::Asciidoctor::PDF::RomanNumeral.new (idx + 1), :lower).to_s)),
      }
    end

    ((start_page - 1)...page_count).each_with_index do |page_idx, idx|
      pagenum_labels[page_idx] = { P: (::PDF::Core::LiteralString.new((idx + 1).to_s)) }
    end

    catalog.data[:PageLabels] = state.store.ref Nums: pagenum_labels.flatten
    nil
  end

  def body_page_start_warn_once message
    @body_page_start_warnings ||= ::Set.new
    log :warn, %(body-page-start: #{message}) if @body_page_start_warnings.add? message
  end
end

Asciidoctor::PDF::Converter.prepend BodyPageStart
