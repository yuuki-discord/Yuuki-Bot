# frozen_string_literal: true

# Copyright Erisa A. (erisa.moe), Spotlight 2016-2020

module YuukiBot
  module Utility
    # Per https://git.io/JLMwW (rest-client@v2.1.0 lib/restclient/payload.rb#L48-L57),
    # a file is any class responding to #path and #read. It additionally use basename.
    # We use StringIO as a parent and implement path and others for File-like functionality.
    class FauxFile < StringIO
      @filename = ''
      @filetype = ''

      def initialize(contents, filename = 'unknown', filetype = 'application/octet-stream')
        super contents

        @filename = filename
        @filetype = filetype
      end

      def path
        @filename
      end

      # Path is assumed to only be the specified filename.
      def original_filename
        path
      end

      def content_type
        @filetype
      end
    end

    YuukiBot.crb.add_command(
      :qr,
      description: 'Generate a QR code from text.',
      arg_format: {
        contents: { name: 'contents', description: 'Value to encode for QR', type: :remaining,
                    max_char: 1000 }
      },
      catch_errors: true
    ) do |event, args|
      filename = 'qr.png'
      content = args.contents

      # Force the size to be 512x512 px.
      qr_code = RQRCode::QRCode.new(content)
      png_data = qr_code.as_png(size: 512)
      qr_file = FauxFile.new png_data.to_blob, filename, 'image/png'

      # Create an embed to wrap the QR code.
      embed = Discordrb::Webhooks::Embed.new
      embed.colour = 0x74f167
      embed.author = Discordrb::Webhooks::EmbedAuthor.new(
        name: "QR Code Generated by #{event.user.distinct}:",
        icon_url: Helper.avatar_url(event.user)
      )
      embed.footer = Discordrb::Webhooks::EmbedFooter.new(
        text: 'Disclaimer: This QR Code is user-generated content.'
      )
      embed.add_field(name: 'QR Content:', value: "```#{content}```")

      # If we set attachment://qr.png as the resulting URL, the attached qr.png
      # will be used as the image, avoiding external image sources.
      embed.image = Discordrb::Webhooks::EmbedImage.new(
        url: "attachment://#{filename}"
      )

      attachments = [qr_file]
      event.channel.send_message('', false, embed, attachments)
    end
  end
end
