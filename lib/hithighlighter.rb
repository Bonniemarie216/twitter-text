
module Twitter
  # Module for doing "hit highlighting" on tweets that have been auto-linked already.  
  # Useful with the results returned from the Search API.
  module HitHighlighter
    # Default Tag used for hit highlighting
    DEFAULT_HIGHLIGHT_TAG = "em"

    # Add <tt><em></em></tt> tags around the <tt>hits</tt> provided in the <tt>text</tt>. The
    # <tt>hits</tt> should be an array of (start, end) index pairs, relative to the original
    # text, before auto-linking (but the <tt>text</tt> may already be auto-linked if desired)
    #
    # The <tt><em></em></tt> tags can be overridden using the <tt>:tag</tt> option. For example:
    #
    #  irb> hit_highlight("test hit here", [[5, 8]], :tag => 'strong')
    #  => "test <strong>hit</strong> here"
    def hit_highlight(text, hits = [], options = {})
      if hits.empty?
        return text
      end

      tag_name = options[:tag] || DEFAULT_HIGHLIGHT_TAG
      tags = ["<" + tag_name + ">", "</" + tag_name + ">"]

      chunks = text.split("<").map do |item|
        item.blank? ? item : item.split(">")
      end.flatten

      result = ""
      chunk_index, chunk = 0, chunks[0]
      prev_chunks_len = 0
      chunk_cursor = 0
      start_in_chunk = false
      for hit, index in hits.flatten.each_with_index do
        tag = tags[index % 2]

        placed = false
        until chunk.nil? || hit < prev_chunks_len + chunk.length do
          result << chunk.mb_chars[chunk_cursor..-1]
          if start_in_chunk && hit == prev_chunks_len + chunk.mb_chars.length
            result << tag
            placed = true
          end

          # correctly handle highlights that end on the final character.
          if tag_text = chunks[chunk_index+1]
            result << "<#{tag_text}>"
          end

          prev_chunks_len += chunk.mb_chars.length
          chunk_cursor = 0
          chunk_index += 2
          chunk = chunks[chunk_index]
          start_in_chunk = false
        end

        if !placed && !chunk.nil?
          hit_spot = hit - prev_chunks_len
          result << chunk.mb_chars[chunk_cursor...hit_spot].to_s + tag
          chunk_cursor = hit_spot
          if index % 2 == 0
            start_in_chunk = true
          end
        end
      end

      if !chunk.nil?
        result << chunk.mb_chars[chunk_cursor..-1]
        for index in chunk_index+1..chunks.length-1
          result << (index.even? ? chunks[index] : "<#{chunks[index]}>")
        end
      end

      result
    end
  end
end