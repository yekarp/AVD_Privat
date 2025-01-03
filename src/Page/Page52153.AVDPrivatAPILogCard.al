page 52153 "AVD Privat API Log Card"
{
    Caption = 'AVD Privat API Log Card';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "AVD Privat API Log";
    Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field(ID; Rec.ID)
                {
                    ToolTip = 'Specifies the value of the ID field.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ToolTip = 'Specifies the value of the Company Name field.';
                }
                field("Bank Acc. No."; Rec."Bank Acc. No.")
                {
                    ToolTip = 'Specifies the value of the Bank Account No. field.', Comment = '%';
                }
                field(Active; Rec.Active)
                {
                    ToolTip = 'Specifies the value of the Active field.';
                }
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    ToolTip = 'Specifies the value of the SystemCreatedAt field.';
                }
                field(SystemCreatedBy; Rec.SystemCreatedBy)
                {
                    ToolTip = 'Specifies the value of the SystemCreatedBy field.';
                }
                field("No. Lines"; Rec."No. Lines")
                {
                    ToolTip = 'Specifies the value of the No. Lines field.';
                }
                field("No. Error Lines"; Rec."No. Error Lines")
                {
                    ToolTip = 'Specifies the value of the No. Error Lines field.';
                }
                field("Without Dupl. No. Error Lines"; Rec."Without Dupl. No. Error Lines")
                {
                    ToolTip = 'Specifies the value of the Without Duplicate No. Error Lines field.';
                }
                field("Last Error"; Rec."Last Error")
                {
                    ToolTip = 'Specifies the value of the Last Error field.';
                }
            }
            group(groupContent)
            {
                Caption = 'Content';

                usercontrol(UserControlContent; WebPageViewer)
                {
                    trigger ControlAddInReady(callbackUrl: Text)
                    begin
                        IsContentReady := true;
                        ContentFillAddIn();
                    end;

                    trigger Callback(data: Text)
                    begin
                        Rec.SetContent(data);
                    end;
                }
            }
            group(groupErrors)
            {
                Caption = 'Errors';

                usercontrol(UserControlError; WebPageViewer)
                {
                    ApplicationArea = All;

                    trigger ControlAddInReady(callbackUrl: Text)
                    begin
                        IsErrorReady := true;
                        ErrorFillAddIn();
                    end;

                    trigger Callback(data: Text)
                    begin
                        // Rec.SetErrorLines(data);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PrivatAPISetup)
            {
                Caption = 'Privat API Setup';
                ApplicationArea = All;
                Image = Setup;
                RunPageMode = View;
                RunObject = page "AVD API Setup Card";
            }
            action(UploadJSON)
            {
                Caption = 'Upload Json';
                Image = UpdateXML;

                trigger OnAction()
                begin
                    AVDPrivatAPIMgt.UploadJsonFile(Rec);
                end;
            }
            action(DownloadJSON)
            {
                Caption = 'Download Json';
                Image = DocInBrowser;

                trigger OnAction()
                begin
                    Rec.Export(true);
                end;
            }
            action(InsertGenJnl)
            {
                Caption = 'Insert General Jornal';
                Image = DocInBrowser;

                trigger OnAction()
                begin
                    if AVDPrivatAPIMgt.GetSetupLine(Rec) then begin
                        AVDPrivatAPIMgt.GenJnlLineOnInsert(Rec, true);
                        Message(lblProcessIsDone)
                    end;
                end;
            }
        }
        area(Promoted)
        {
            actionref(PrivatAPISetup_Promoted; PrivatAPISetup) { }
            actionref(UploadJSON_Promoted; UploadJSON) { }
            actionref(DownloadJSON_Promoted; DownloadJSON) { }
            actionref(InsertGenJnl_Promoted; InsertGenJnl) { }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ContentLines := Rec.GetContent();
        ErrorLines := Rec.GetErrorLines();

        if IsContentReady then
            ContentFillAddIn();

        if IsErrorReady then
            ErrorFillAddIn();
    end;

    local procedure ContentFillAddIn()
    begin
        CurrPage.UserControlContent.SetContent(StrSubstNo('<textarea Id="TextArea" maxlength="%2" style="width:100%;height:100%;resize: none; font-family: "Segoe UI", "Segoe WP", Segoe, device-segoe, Tahoma, Helvetica, Arial, sans-serif !important; font-size: 10.5pt !important;" OnChange="window.parent.WebPageViewerHelper.TriggerCallback(document.getElementById(''TextArea'').value)">%1</textarea>', ContentLines, MaxStrLen(ContentLines)));
    end;

    local procedure ErrorFillAddIn()
    begin
        CurrPage.UserControlError.SetContent(StrSubstNo('<textarea Id="TextArea" maxlength="%2" style="width:100%;height:100%;resize: none; font-family:"Segoe UI", "Segoe WP", Segoe, device-segoe, Tahoma, Helvetica, Arial, sans-serif !important; font-size: 10.5pt !important;" OnChange="window.parent.WebPageViewerHelper.TriggerCallback(document.getElementById(''TextArea'').value)">%1</textarea>', ErrorLines, MaxStrLen(ErrorLines)));
    end;

    var
        AVDPrivatAPIMgt: Codeunit "AVD Privat API Mgt";
        lblProcessIsDone: Label 'Process Is Done!';
        ContentLines, ErrorLines : Text;
        IsContentReady, IsErrorReady : Boolean;
}