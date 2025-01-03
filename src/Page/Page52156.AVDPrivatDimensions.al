page 52156 "AVD Privat Dimensions"
{
    Caption = 'AVD Privat Dimensions';
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "AVD Privat Dimension";
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Bank Acc. No."; Rec."Bank Acc. No.")
                {
                    ToolTip = 'Specifies the value of the Bank Account No. field.', Comment = '%';
                    Visible = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    ToolTip = 'Specifies the value of the Line No. field.', Comment = '%';
                    Visible = false;
                }
                field("Income Dimension Code"; Rec."Income Dimension Code")
                {
                    ToolTip = 'Specifies the value of the Income Dimension Code field.', Comment = '%';
                }
                field("Income Dimension Value"; Rec."Income Dimension Value")
                {
                    ToolTip = 'Specifies the value of the Income Dimension Value field.', Comment = '%';
                }
                field(Blocked; Rec.Blocked)
                {
                    ToolTip = 'Specifies the value of the Blocked field.', Comment = '%';
                }
            }
        }
    }
}