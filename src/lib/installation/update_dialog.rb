# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2016 SUSE LLC
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# ------------------------------------------------------------------------------

require "yast"
require "ui/installation_dialog"

module Installation
  class UpdateDialog < ::UI::InstallationDialog
    def initialize
      super

      textdomain "self_update"
    end

    def dialog_title
      _("Installer Update")
    end

    def help_text
      _("Updates could fix some parts of current installer so\n" \
        "we recommend to fix your network configuration and try\n" \
        "again but if by circunstance you are not able to, just\n" \
        "continue to the next dialog.")
    end

    def dialog_content
      VBox(
        network_button,
        VStretch(),
        HSquash(
          VBox(
            VSpacing(1),
            Left(Heading(_("Check for Updates"))),
            VSpacing(1),
            Label(description_dialog),
            VSpacing(1),
            update_button
          )
        ),
        VStretch()
      )
    end

    def description_dialog
      _("It was impossible to reach updates server. We recommend to\n" \
        "check network configuration and try again as applying some\n" \
        "important updates for the current installation could solve\n" \
        "some unexpected issues.")
    end

    def network_handler
      Yast::WFM.CallFunction("inst_lan", [GetInstArgs.argmap.merge("skip_detection" => true)])
    end

    def update_handler
      :update
    end

    # UI term for the network configuration button (or empty if not needed)
    # @return [Yast::Term] UI term
    def update_button
      Left(PushButton(Id(:update), _("Check Now")))
    end

    # UI term for the network configuration button (or empty if not needed)
    # @return [Yast::Term] UI term
    def network_button
      Right(PushButton(Id(:network), _("Network Configuration...")))
    end
  end
end
