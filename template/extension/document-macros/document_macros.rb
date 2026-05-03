# frozen_string_literal: true

require 'asciidoctor/extensions'
require 'asciidoctor-pdf'

module AvikusDocumentMacros
  PAGES_DIR = ::File.expand_path '../../pages', __dir__
  PROPRIETARY_WARNING_NAME = 'avikus-proprietary-warning'
  PARTIALS = {
    'doc-info-page' => 'document_info_page.adoc',
    PROPRIETARY_WARNING_NAME => 'avikus_proprietary_warning.adoc',
    'figure-list' => 'figure_list.adoc',
    'table-list' => 'table_list.adoc',
  }.freeze
  CONFIDENTIAL_TEXT = 'COMPANY CONFIDENTIAL'
  CONFIDENTIAL_ALIGNMENTS = %w[left right center].freeze
  CONFIDENTIAL_DEFAULT_FONT_COLOR = 'CC0000'
  CONFIDENTIAL_DEFAULT_FONT_STYLE = :bold
  DOC_INFO_TITLE_DEFAULTS = {
    font_style: :bold,
    font_size: 23,
    font_color: '000000',
    margin_top: 12,
    margin_bottom: 4,
  }.freeze
  DOC_INFO_SUBTITLE_DEFAULTS = {
    font_size: 18,
    font_color: '659ADD',
    margin_top: 4,
    margin_bottom: 12,
  }.freeze
  WARNING_BOX_DEFAULTS = {
    margin_top: '10cm',
    padding: [14, 18, 14, 18],
  }.freeze
  WARNING_TITLE_DEFAULTS = {
    font_style: :bold,
    font_size: 12,
    font_color: 'CC0000',
    margin_bottom: 4,
  }.freeze
  WARNING_BODY_DEFAULTS = {
    font_size: 9.5,
    font_color: '333333',
  }.freeze

  class PartialMacro < ::Asciidoctor::Extensions::BlockMacroProcessor
    use_dsl

    def process parent, target, attrs
      partial_name = config[:partial_name]
      partial_path = ::File.join PAGES_DIR, partial_name
      raise %(missing document macro partial: #{partial_path}) unless ::File.file? partial_path

      parse_content parent, ::File.readlines(partial_path, chomp: true)
      nil
    end
  end

  class ConfidentialMacro < ::Asciidoctor::Extensions::BlockMacroProcessor
    use_dsl
    named :confidential

    def process parent, target, attrs
      target = target.to_s
      attrs = attrs.merge 'text' => (target.empty? ? CONFIDENTIAL_TEXT : target)
      create_block parent, :confidential, nil, attrs
    end
  end

  class InfoTableMacro < ::Asciidoctor::Extensions::BlockMacroProcessor
    use_dsl
    named :'info-table'

    def process parent, target, attrs
      prefix = (attrs['prefix'] || target).to_s.strip
      raise 'info-table macro requires a prefix' if prefix.empty?

      entries = collect_entries parent.document, prefix
      return nil if entries.empty?

      parse_content parent, table_lines(entries)
      nil
    end

    private

    def collect_entries doc, prefix
      attr_prefix = %(#{prefix}-)
      full_row_prefix = %(#{prefix}-f-)
      doc.attributes.each_with_object [] do |(name, value), entries|
        name = name.to_s
        next unless name.start_with? attr_prefix

        full_row = name.start_with? full_row_prefix
        key = name.delete_prefix(full_row ? full_row_prefix : attr_prefix)
        next if key.empty?

        entries << {
          label: key.tr('-_', ' ').upcase,
          value: value.to_s,
          full_row: full_row,
        }
      end
    end

    def table_lines entries
      lines = ['[cols=".^2h,.^3,.^2h,.^3"]', '|===']
      row = []

      entries.each do |entry|
        if entry[:full_row]
          append_pair_row lines, row unless row.empty?
          row = []
          append_full_row lines, entry
        else
          row << entry
          if row.size == 2
            append_pair_row lines, row
            row = []
          end
        end
      end

      append_pair_row lines, row unless row.empty?
      lines << '|==='
    end

    def append_pair_row lines, row
      row.each do |entry|
        lines << %(| #{entry[:label]})
        lines.concat value_cell_lines(entry[:value])
      end
      (2 - row.size).times do
        lines << '|'
        lines << '|'
      end
    end

    def append_full_row lines, entry
      lines << %(| #{entry[:label]})
      lines.concat value_cell_lines(entry[:value], colspan: 3)
    end

    def value_cell_lines value, colspan: nil
      item_lines = value.gsub(/\r\n?/, "\n").split("\n").map(&:strip)
      multiline = item_lines.size > 1
      item_lines = item_lines.reject(&:empty?)
      item_lines = [''] if item_lines.empty?

      if multiline
        marker = colspan ? %(#{colspan}+a|) : 'a|'
        [marker] + item_lines.map {|line| %(* #{line}) }
      else
        marker = colspan ? %(#{colspan}+|) : '|'
        [%(#{marker} #{item_lines.first})]
      end
    end
  end

  module PdfConverter
    def convert_open node
      case node.style
      when 'doc-info-title'
        convert_doc_info_text node, :role_abstract_title, DOC_INFO_TITLE_DEFAULTS
      when 'doc-info-subtitle'
        convert_doc_info_text node, :role_abstract_subtitle, DOC_INFO_SUBTITLE_DEFAULTS
      when PROPRIETARY_WARNING_NAME
        convert_avikus_proprietary_warning node
      else
        super
      end
    end

    def convert_confidential node
      align = (node.attr 'align', 'right').downcase
      align = 'right' unless CONFIDENTIAL_ALIGNMENTS.include? align
      text = node.attr 'text', CONFIDENTIAL_TEXT
      configured_font_size = node.attr 'font-size'
      fallback_font_color = @theme.role_abstract_confidential_label_font_color || CONFIDENTIAL_DEFAULT_FONT_COLOR
      fallback_font_style = (@theme.role_abstract_confidential_label_font_style&.to_sym ||
        CONFIDENTIAL_DEFAULT_FONT_STYLE)
      inherited_styles = fallback_font_style == font_style ? nil : [fallback_font_style]

      theme_font :role_abstract_confidential_label do
        previous_font_color = @font_color
        @font_color = fallback_font_color
        font_size configured_font_size.to_f if configured_font_size && configured_font_size.to_f.positive?
        ink_prose text, align: align.to_sym, margin: 0, styles: inherited_styles
      ensure
        @font_color = previous_font_color
      end
    end

    def convert_doc_info_text node, category, defaults
      text = node_text node
      with_theme_font_fallback category, defaults do
        ink_prose text,
          margin_top: theme_length(category, :margin_top, defaults[:margin_top]),
          margin_bottom: theme_length(category, :margin_bottom, defaults[:margin_bottom])
      end
    end

    def convert_avikus_proprietary_warning node
      paragraphs = paragraph_children node
      title = paragraph_text(paragraphs.shift)
      body = paragraphs.map {|paragraph| paragraph_text paragraph }.join "\n\n"

      height = measure_avikus_proprietary_warning node, title, body
      if height && height <= bounds.top
        move_avikus_proprietary_warning_to_page_bottom height
        node.set_attr 'unbreakable-option', ''
      else
        margin_top theme_length(:role_abstract_proprietary_box, :margin_top, WARNING_BOX_DEFAULTS[:margin_top])
      end
      arrange_block node do |extent|
        add_dest_for_block node if node.id
        tare_first_page_content_stream do
          theme_fill_and_stroke_block :avikus_proprietary_warning, extent
        end
        ink_avikus_proprietary_warning node, title, body
      end
      theme_margin :block, :bottom, (next_enclosed_block node)
    end

    def measure_avikus_proprietary_warning node, title, body
      doc = node.document
      (dry_run keep_together: true, single_page: :enforce do
        push_scratch doc
        ink_avikus_proprietary_warning node, title, body
      ensure
        pop_scratch doc
      end).single_page_height
    rescue ::Prawn::Errors::CannotFit
      nil
    end

    def move_avikus_proprietary_warning_to_page_bottom height
      advance_page if cursor < height && !at_page_top?
      move_cursor_to height if cursor > height
    end

    def ink_avikus_proprietary_warning node, title, body
      pad_box (@theme.avikus_proprietary_warning_padding || WARNING_BOX_DEFAULTS[:padding]), node do
        with_theme_font_fallback :role_abstract_proprietary_title, WARNING_TITLE_DEFAULTS do
          ink_prose title, margin_bottom: theme_length(:role_abstract_proprietary_title, :margin_bottom,
            WARNING_TITLE_DEFAULTS[:margin_bottom])
        end
        with_theme_font_fallback :role_abstract_proprietary_body, WARNING_BODY_DEFAULTS do
          ink_prose body, margin_bottom: 0, normalize: false
        end
      end
    end

    def with_theme_font_fallback category, defaults
      family = @theme[%(#{category}_font_family)] || defaults[:font_family] || font_family
      size = @theme[%(#{category}_font_size)] || defaults[:font_size] || font_size
      style = @theme[%(#{category}_font_style)] || defaults[:font_style]
      color = @theme[%(#{category}_font_color)] || defaults[:font_color] || @font_color
      font_options = { size: size }
      font_options[:style] = style.to_sym if style
      previous_font_color = @font_color
      @font_color = color
      font family, font_options do
        yield
      ensure
        @font_color = previous_font_color
      end
    end

    def theme_length category, name, fallback = nil
      value = @theme[%(#{category}_#{name})] || fallback
      return 0 if value.nil?

      ::String === value ? (str_to_pt value) : value.to_f
    end

    def paragraph_children node
      node.blocks.select {|block| block.context == :paragraph }
    end

    def node_text node
      paragraphs = paragraph_children node
      return paragraphs.map(&:content).join "\n\n" unless paragraphs.empty?

      node.content.to_s
    end

    def paragraph_text paragraph
      return '' unless paragraph

      if paragraph.lines.empty?
        paragraph.content.to_s
      else
        paragraph.lines.map {|line| line.sub(/[[:space:]]\+\z/, '') }.join "\n"
      end
    end
  end
end

Asciidoctor::Extensions.register do
  block_macro AvikusDocumentMacros::PartialMacro, :'doc-info-page',
    partial_name: AvikusDocumentMacros::PARTIALS.fetch('doc-info-page')

  block_macro AvikusDocumentMacros::ConfidentialMacro

  block_macro AvikusDocumentMacros::InfoTableMacro

  block_macro AvikusDocumentMacros::PartialMacro, :'avikus-proprietary-warning',
    partial_name: AvikusDocumentMacros::PARTIALS.fetch(AvikusDocumentMacros::PROPRIETARY_WARNING_NAME)

  block_macro AvikusDocumentMacros::PartialMacro, :'figure-list',
    partial_name: AvikusDocumentMacros::PARTIALS.fetch('figure-list')

  block_macro AvikusDocumentMacros::PartialMacro, :'table-list',
    partial_name: AvikusDocumentMacros::PARTIALS.fetch('table-list')
end

Asciidoctor::PDF::Converter.prepend AvikusDocumentMacros::PdfConverter
