#! /usr/bin/env rspec

require_relative "./test_helper"

require "installation/select_system_role"
Yast.import "ProductControl"

describe ::Installation::SelectSystemRole do
  subject { Installation::SelectSystemRole.new }

  before do
    allow(Yast::ProductControl).to receive(:GetTranslatedText) do |s|
      "Lorem Ipsum #{s}"
    end

    allow(Yast::UI).to receive(:ChangeWidget)
  end

  describe "#run" do
    before do
      # reset previous test
      subject.class.original_role_id = nil
      subject.class.client_to_show   = nil

      allow(Yast::ProductFeatures).to receive(:ClearOverlay)
      allow(Yast::ProductFeatures).to receive(:SetOverlay) # .with
    end

    context "when no roles are defined" do
      before do
        allow(Yast::ProductControl).to receive(:productControl)
          .and_return("system_roles" => [])
      end

      it "does not display dialog, and returns :auto" do
        expect(Yast::Wizard).to_not receive(:SetContents)
        expect(subject.run).to eq(:auto)
      end
    end

    context "when some roles are defined" do
      let(:control_file_roles) do
        [
          { "id" => "foo", "partitioning" => { "format" => true } },
          { "id" => "bar", "software" => { "desktop" => "knome" }, "additional_dialogs" => "a,b" }
        ]
      end

      before do
        allow(Yast::ProductControl).to receive(:productControl)
          .and_return("system_roles" => control_file_roles)
      end

      it "displays dialog, and sets ProductFeatures on Next" do
        allow(Yast::Wizard).to receive(:SetContents)
        allow(Yast::UI).to receive(:UserInput)
          .and_return(:next)
        allow(Yast::UI).to receive(:QueryWidget)
          .with(Id(:roles), :CurrentButton).and_return("foo")

        expect(Yast::ProductFeatures).to receive(:ClearOverlay)
        expect(Yast::ProductFeatures).to receive(:SetOverlay) # .with

        expect(subject.run).to eq(:next)
      end

      it "displays dialog, and leaves ProductFeatures on Back" do
        allow(Yast::Wizard).to receive(:SetContents)
        allow(Yast::UI).to receive(:UserInput)
          .and_return(:back)
        expect(Yast::ProductFeatures).to receive(:ClearOverlay)
        expect(Yast::ProductFeatures).to_not receive(:SetOverlay)

        expect(subject.run).to eq(:back)
      end

      context "when a role contains additional dialogs" do
        it "shows the first dialog when going forward" do
          allow(Yast::Wizard).to receive(:SetContents)
          allow(Yast::UI).to receive(:UserInput)
            .and_return(:next)
          allow(Yast::UI).to receive(:QueryWidget)
            .with(Id(:roles), :CurrentButton).and_return("bar")

          allow(Yast::WFM).to receive(:CallFunction).and_return(:next)
          expect(Yast::WFM).to receive(:CallFunction).with("a", anything).and_return(:next)

          expect(subject.run).to eq(:next)
        end

        it "shows the last dialog when going back" do
          subject.class.original_role_id = "bar"
          subject.class.client_to_show = 1
          allow(Yast::GetInstArgs).to receive(:going_back).and_return(true)
          expect(Yast::Wizard).to_not receive(:SetContents)
          expect(Yast::UI).to_not receive(:UserInput)
          expect(Yast::UI).to_not receive(:QueryWidget)

          expect(Yast::WFM).to receive(:CallFunction).with("b", anything).and_return(:next)

          expect(subject.run).to eq(:next)
        end
      end

      context "when re-selecting the same role" do
        it "just proceeds without a popup" do
          subject.class.original_role_id = "foo"

          allow(Yast::Wizard).to receive(:SetContents)
          allow(Yast::UI).to receive(:UserInput)
            .and_return(:next)
          allow(Yast::UI).to receive(:QueryWidget)
            .with(Id(:roles), :CurrentButton).and_return("foo")

          expect(Yast::Popup).to_not receive(:ContinueCancel)

          expect(Yast::ProductFeatures).to receive(:ClearOverlay)
          expect(Yast::ProductFeatures).to receive(:SetOverlay)

          expect(subject.run).to eq(:next)
        end
      end

      context "when re-selecting a different role" do
        it "displays a popup, and proceeds if Continue is answered" do
          subject.class.original_role_id = "bar"

          allow(Yast::Wizard).to receive(:SetContents)
          allow(Yast::UI).to receive(:UserInput)
            .and_return(:next)
          allow(Yast::UI).to receive(:QueryWidget)
            .with(Id(:roles), :CurrentButton).and_return("foo")

          expect(Yast::Popup).to receive(:ContinueCancel)
            .and_return(true)

          expect(Yast::ProductFeatures).to receive(:ClearOverlay)
          expect(Yast::ProductFeatures).to receive(:SetOverlay)

          expect(subject.run).to eq(:next)
        end

        it "displays a popup, and does not proceed if Cancel is answered" do
          subject.class.original_role_id = "bar"

          allow(Yast::Wizard).to receive(:SetContents)
          allow(Yast::UI).to receive(:UserInput)
            .and_return(:next, :back)
          allow(Yast::UI).to receive(:QueryWidget)
            .with(Id(:roles), :CurrentButton).and_return("foo")

          expect(Yast::Popup).to receive(:ContinueCancel)
            .and_return(false)
          expect(Yast::ProductFeatures).to receive(:ClearOverlay)
          expect(Yast::ProductFeatures).to_not receive(:SetOverlay)

          expect(subject.run).to eq(:back)
        end
      end
    end
  end
end
