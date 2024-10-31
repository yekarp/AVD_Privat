page 52051 "AVD API Setup Card"
{
    Caption = 'AVD API Setup Card';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "AVD Privat API Setup";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Client ID"; Rec."Client ID")
                {
                    ToolTip = 'Specifies the value of the Client ID field.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the value of the Description field.';
                }
                field("Client ID Key"; Rec."Client ID Key")
                {
                    ToolTip = 'Specifies the value of the Client ID Key field.';
                }
                field("API Url"; Rec."API Url")
                {
                    MultiLine = true;
                    ToolTip = 'Specifies the value of the API Url field.';
                }
                field("Next Page Parameter"; Rec."Next Page Parameter")
                {
                    ToolTip = 'Specifies the value of the Next Page Parameter field.';
                }
                field("Content Type"; Rec."Content Type")
                {
                    ToolTip = 'Specifies the value of the Content Type field.';
                }
                field("Token Key"; Rec."Token Key")
                {
                    ToolTip = 'Specifies the value of the Token Key field.';
                }
                field("Limit Records"; Rec."Limit Records")
                {
                    ToolTip = 'Specifies the value of the Limit Records field.';
                }
                field("Privat Registration No."; Rec."Privat Registration No.")
                {
                    ToolTip = 'Specifies the value of the Privat Registration No. field.';
                }
            }
            group(GeneralJnl)
            {
                Caption = 'General Journal';

                field("Org. form F1"; Rec."Org. form F1")
                {
                    ToolTip = 'Specifies the value of the Org. form F1 field.';
                }
                field("Org. form F2"; Rec."Org. form F2")
                {
                    ToolTip = 'Specifies the value of the Org. form F2 field.';
                }
                field("Org. form LLC"; Rec."Org. form LLC")
                {
                    ToolTip = 'Specifies the value of the Org. form LLC field.';
                }
                field("RegEx Pattern"; Rec."RegEx Pattern")
                {
                    ToolTip = 'Specifies the value of the RegEx Pattern field.';
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ToolTip = 'Specifies the value of the Global Dimension 2 Code field.';
                }
            }
            part(partSetupLines; "AVD Setup Lines")
            {
                Caption = 'Lines';
            }
            part(partPrivatDimensions; "AVD Privat Dimensions")
            {
                Caption = 'Income Dimensions';
                Provider = partSetupLines;
                SubPageLink = "Bank Acc. No." = field("Bank Acc. No.");
            }
            group(Dialog)
            {
                Caption = 'Dialog';

                field("Post Line"; Rec."Post Line")
                {
                    ToolTip = 'Specifies the value of the Post Line field.';
                }
                field("Preview Check"; Rec."Preview Check")
                {
                    ToolTip = 'Specifies the value of the Preview Check field.';
                }
                field("Duplicate Posted Entry"; Rec."Duplicate Posted Entry")
                {
                    ToolTip = 'Specifies the value of the Duplicate Posted Entry field.';
                }
                field("Show Dialog No. Lines"; Rec."Show Dialog No. Lines")
                {
                    ToolTip = 'Specifies the value of the Show Dialog No. Lines field.';
                }
                field("Update Dialog No. Lines"; Rec."Update Dialog No. Lines")
                {
                    ToolTip = 'Specifies the value of the Update Dialog No. Lines field.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}