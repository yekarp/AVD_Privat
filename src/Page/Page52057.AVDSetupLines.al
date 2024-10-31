page 52057 "AVD Setup Lines"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "AVD Privat API Setup Line";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                Caption = 'General';

                field("Bank Acc. No."; Rec."Bank Acc. No.")
                {
                    ToolTip = 'Specifies the value of the Bank Account No. field.', Comment = '%';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the value of the Description field.', Comment = '%';
                }
                field("Bank Jnl. Template"; Rec."Bank Jnl. Template")
                {
                    ToolTip = 'Specifies the value of the Bank Jnl. Template field.', Comment = '%';
                }
                field("Bank Jnl. for Customer"; Rec."Bank Jnl. for Customer")
                {
                    ToolTip = 'Specifies the value of the Bank Jnl. for Customer field.', Comment = '%';
                }
                field("Bank Jnl. for Analisys"; Rec."Bank Jnl. for Analisys")
                {
                    ToolTip = 'Specifies the value of the Bank Jnl. for Analisys field.', Comment = '%';
                }
                field("Bank Jnl. for Vendor"; Rec."Bank Jnl. for Vendor")
                {
                    ToolTip = 'Specifies the value of the Bank Jnl. for Vendor field.', Comment = '%';
                }
                field("Owner Organization Form"; Rec."Owner Organization Form")
                {
                    ToolTip = 'Specifies the value of the Owner Organization Form field.', Comment = '%';
                }
                field(TokenMasked; TokenMasked)
                {
                    Caption = 'Token';
                    ToolTip = 'Specifies the value of the Token field.', Comment = '%';

                    trigger OnValidate()
                    begin
                        TokenOnValidate()
                    end;
                }
                // field(Token; Rec.Token)
                // {
                //     ToolTip = 'Specifies the value of the Token field.', Comment = '%';
                //     ExtendedDatatype = Masked;
                //     Visible = false;
                // }
                field(Blocked; Rec.Blocked)
                {
                    ToolTip = 'Specifies the value of the Blocked field.', Comment = '%';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        InitToken();
    end;

    local procedure InitToken()
    begin
        TokenMasked := '';
        if Rec.Token <> '' then
            TokenMasked := TokenMaskedLbl;
    end;

    local procedure TokenOnValidate()
    begin
        if Rec.Token <> TokenMasked then
            Rec.Token := TokenMasked;
        InitToken();
    end;

    var
        TokenMasked: Text[500];
        TokenMaskedLbl: Label '***********', Locked = true;
}