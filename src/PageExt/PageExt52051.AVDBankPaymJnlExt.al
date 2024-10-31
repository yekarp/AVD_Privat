pageextension 52051 "AVD Bank Paym. Jnl Ext" extends "SMA Bank Payment Journal"
{

    layout
    {
        // Add changes to page layout here
        addlast(Group)
        {

            field("AVD Error Text"; Rec."AVD Error Text")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Error Text field.';
                Editable = false;
            }
        }
    }
}