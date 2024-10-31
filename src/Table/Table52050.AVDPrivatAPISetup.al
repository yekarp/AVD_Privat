table 52050 "AVD Privat API Setup"
{

    fields
    {
        field(1; Primary; Code[10])
        {
            Caption = 'Primary';
        }
        field(2; "API Url"; Text[350])
        {
            Caption = 'API Url';
        }
        field(7; "Limit Records"; Integer)
        {
            Caption = 'Limit Records';
        }
        field(8; "Privat Registration No."; Text[20])
        {
            Caption = 'Privat Registration No.';
        }
        field(9; "Org. form LLC"; Code[10])
        {
            Caption = 'Org. form LLC';
            TableRelation = "SMA Organization Form";
        }
        field(10; "Org. form F1"; Code[10])
        {
            Caption = 'Org. form F1';
            TableRelation = "SMA Organization Form";
        }
        field(11; "Org. form F2"; Code[10])
        {
            Caption = 'Org. form F2';
            TableRelation = "SMA Organization Form";
        }
        field(13; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(14; "Show Dialog No. Lines"; Integer)
        {
            Caption = 'Show Dialog No. Lines';
            MinValue = 0;
        }
        field(15; "Update Dialog No. Lines"; Integer)
        {
            Caption = 'Update Dialog No. Lines';
            MinValue = 0;
        }
        field(16; "Duplicate Posted Entry"; Boolean)
        {
            Caption = 'Duplicate Posted Entry';
        }
        field(17; "RegEx Pattern"; Text[30])
        {
            Caption = 'RegEx Pattern';
        }
        field(18; "Client ID Key"; Text[30])
        {
            Caption = 'Client ID Key';
        }
        field(19; "Token Key"; Text[30])
        {
            Caption = 'Token Key';
        }
        field(20; "Content Type"; Text[50])
        {
            Caption = 'Content Type';
        }
        field(21; "Next Page Parameter"; Text[50])
        {
            Caption = 'Next Page Parameter';
        }
        field(22; "Preview Check"; Boolean)
        {
            Caption = 'Preview Check';
        }
        field(23; "Client ID"; Text[50])
        {
            Caption = 'Client ID';
        }
        field(25; "Post Line"; Boolean)
        {
            Caption = 'Post Line';
        }
        field(26; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));
        }
    }

    keys
    {
        key(PK; Primary)
        {
            Clustered = true;
        }
    }
}