tableextension 52051 "AVD Gen Jnl Line Ext" extends "Gen. Journal Line"
{
    fields
    {
        // Add changes to table fields here
        field(52050; "AVD Error Text"; Text[2048])
        {
            Caption = 'Error Text';
        }
    }
}