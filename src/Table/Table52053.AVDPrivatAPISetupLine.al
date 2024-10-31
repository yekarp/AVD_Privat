table 52053 "AVD Privat API Setup Line"
{

    LookupPageId = "AVD Setup Lines";
    DrillDownPageId = "AVD Setup Lines";

    fields
    {
        field(1; "Bank Acc. No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account"."No." where("SMA Account Type" = const("Bank Account"), Blocked = const(false));
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            FieldClass = FlowField;
            CalcFormula = lookup("Bank Account".Name where("No." = field("Bank Acc. No.")));
        }
        field(3; Token; Text[500])
        {
            Caption = 'Token';
        }
        field(4; "Bank Jnl. Template"; Code[20])
        {
            Caption = 'Bank Jnl. Template';
            TableRelation = "Gen. Journal Template";
        }
        field(5; "Bank Jnl. for Customer"; Code[20])
        {
            Caption = 'Bank Jnl. for Customer';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Bank Jnl. Template"));
        }
        field(6; "Bank Jnl. for Vendor"; Code[20])
        {
            Caption = 'Bank Jnl. for Vendor';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Bank Jnl. Template"));
        }
        field(7; "Bank Jnl. for Analisys"; Code[20])
        {
            Caption = 'Bank Jnl. for Analisys';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Bank Jnl. Template"));
        }
        field(8; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(9; "Owner Organization Form"; Code[10])
        {
            Caption = 'Owner Organization Form';
            TableRelation = "SMA Organization Form";
        }
    }

    keys
    {
        key(PK; "Bank Acc. No.")
        {
            Clustered = true;
        }
    }
}