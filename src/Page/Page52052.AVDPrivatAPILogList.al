page 52052 "AVD Privat API Log List"
{
    Caption = 'AVD Privat API Log List';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    CardPageId = "AVD Privat API Log Card";
    SourceTable = "AVD Privat API Log";
    // Editable = false;
    SourceTableView = sorting(ID) order(Descending);

    layout
    {
        area(Content)
        {
            repeater(repGroup)
            {

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
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    ToolTip = 'Specifies the value of the SystemCreatedAt field.';
                }
                field(SystemCreatedBy; Rec.SystemCreatedBy)
                {
                    ToolTip = 'Specifies the value of the SystemCreatedBy field.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CreateJobQueue)
            {
                Caption = 'Create Job Queue';
                ApplicationArea = All;
                Image = JobTimeSheet;

                trigger OnAction()
                begin
                    AVDPrivatJobQueue.EnqueueJobEntry();
                    Message('Job Queue is created!');
                end;
            }
            action(ManualPrivatAPI)
            {
                Caption = 'Manual Privat API';
                ApplicationArea = All;
                Image = TestDatabase;

                trigger OnAction()
                begin
                    ClearLastError();
                    if Codeunit.Run(Codeunit::"AVD Privat API Mgt") then
                        Message(lblProcessIsDone)
                    else
                        Message(GetLastErrorText());
                end;
            }
            action(ManualDateFilterPrivatAPI)
            {
                Caption = 'Manual Date Filter Privat API';
                ApplicationArea = All;
                Image = TestDatabase;

                trigger OnAction()
                begin
                    AVDPrivatAPIMgt.PrivatOnProcessWithManualDateFilter();
                    Message(lblProcessIsDone)
                end;
            }
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
                ApplicationArea = All;
                Image = UpdateXML;

                trigger OnAction()
                begin
                    AVDPrivatAPIMgt.UploadJsonFile(Rec);
                end;
            }
            action(DownloadJSON)
            {
                Caption = 'Download Json';
                ApplicationArea = All;
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
                    // if AVDPrivatAPIMgt.GetSetupLine(Rec) then begin
                    AVDPrivatAPIMgt.GenJnlLineOnInsert(Rec, true);
                    Message(lblProcessIsDone)
                    // end;
                end;
            }
        }
        area(Promoted)
        {
            actionref(PrivatAPISetup_Promoted; PrivatAPISetup) { }
            group(PrivatAPI)
            {
                Caption = 'Privat API';
                actionref(CreateJobQueue_Promoted; CreateJobQueue) { }
                actionref(TestPrivatAPI_Promoted; ManualPrivatAPI) { }
                actionref(ManualDateFilterPrivatAPI_Promoted; ManualDateFilterPrivatAPI) { }
            }
            group(JSON)
            {
                Caption = 'JSON';
                actionref(UploadJSON_Promoted; UploadJSON) { }
                actionref(DownloadJSON_Promoted; DownloadJSON) { }
            }
            actionref(InsertGenJnl_Promoted; InsertGenJnl) { }
        }
    }

    var
        AVDPrivatJobQueue: Codeunit "AVD Privat Job Queue";
        AVDPrivatAPIMgt: Codeunit "AVD Privat API Mgt";
        lblProcessIsDone: Label 'Process Is Done!';
}