table 52052 "AVD Privat Dimension"
{
    Caption = 'AVD Privat Dimension';

    fields
    {
        field(1; "Bank Acc. No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account"."No." where(Blocked = const(false));
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Income Dimension Code"; Code[20])
        {
            Caption = 'Income Dimension Code';
            TableRelation = "Dimension".Code where(Blocked = const(false));
        }
        field(4; "Income Dimension Value"; Code[20])
        {
            Caption = 'Income Dimension Value';
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Income Dimension Code"),
                                                          Blocked = const(false));
        }
        field(5; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
    }

    keys
    {
        key(PK; "Bank Acc. No.", "Line No.")
        {
            Clustered = true;
        }
    }
}