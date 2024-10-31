page 52055 "AVD Manual Date Filter"
{
    Caption = 'AVD Manual Date Filter';
    PageType = StandardDialog;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                ShowCaption = false;

                field(BankAccNoFilter; BankAccNoFilter)
                {
                    Caption = 'Bank Account No. Filter';
                    TableRelation = "AVD Privat API Setup Line"."Bank Acc. No." where(Blocked = const(false));

                    // trigger OnValidate()
                    // begin
                    //     BankAccNoFilterOnValidate();
                    // end;

                    // trigger OnDrillDown()
                    // begin
                    //     BankAccNoFilterOnDrillDown();
                    // end;
                }
                field(StartingDate; StartingDate)
                {
                    Caption = 'Starting Date';

                    trigger OnValidate()
                    begin
                        CheckDateFilter();
                    end;
                }
                field(EndingDate; EndingDate)
                {
                    Caption = 'Ending Date';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if StartingDate = 0D then
            StartingDate := CalcDate('<-1D>', Today);
        if EndingDate = 0D then
            EndingDate := Today;
    end;

    procedure GetManualDateFilter(var xStartingDate: Text[20]; var xEndingDate: Text[20]; var xBankAccNoFilter: Text[250])
    begin
        xBankAccNoFilter := BankAccNoFilter;
        xStartingDate := Format(StartingDate, 0, '<Day,2>-<Month,2>-<Year4>');
        xEndingDate := Format(EndingDate, 0, '<Day,2>-<Month,2>-<Year4>');
    end;

    local procedure CheckDateFilter();
    begin
        if (StartingDate = 0D) or (EndingDate = 0D) then exit;

        if StartingDate > EndingDate then
            Error(StartingDateMustBeMoreOrEqualEndingDateErr);
    end;

    var
        StartingDate, EndingDate : Date;
        BankAccNoFilter: Text;
        StartingDateMustBeMoreOrEqualEndingDateErr: Label 'Starting Date Must Be Less Or Equal Ending Date!';
}