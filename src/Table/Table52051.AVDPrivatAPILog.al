table 52051 "AVD Privat API Log"
{
    DataClassification = CustomerContent;
    DataPerCompany = false;

    fields
    {
        field(1; "ID"; Integer)
        {
            Caption = 'ID';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            TableRelation = Company.Name;
        }
        field(3; "Content"; Blob)
        {
            Caption = 'Content';
        }
        field(4; "Bank Acc. No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account"."No.";
        }
        // field(5; "Insert To Temp Duration"; Duration)
        // {
        //     Caption = 'Insert To Temp Duration';
        // }
        field(6; "No. Lines"; Integer)
        {
            Caption = 'No. Lines';
        }
        field(7; "Error Lines"; Blob)
        {
            Caption = 'Error Lines';
        }
        field(8; "No. Error Lines"; Integer)
        {
            Caption = 'No. Error Lines';
        }
        field(9; "Active"; Boolean)
        {
            Caption = 'Active';
        }
        // field(10; "Insert Duration"; Duration)
        // {
        //     Caption = 'Insert Total Duration';
        // }
        field(11; "Last Error"; Text[2048])
        {
            Caption = 'Last Error';
        }
        field(12; "Without Dupl. No. Error Lines"; Integer)
        {
            Caption = 'Without Duplicate No. Error Lines';
        }
    }

    keys
    {
        key(PK; "ID")
        {
            Clustered = true;
        }
        key(SK1; "Company Name", "Bank Acc. No.", Active) { }
    }

    trigger OnInsert()
    begin
        "Company Name" := CompanyName;
        Active := true;
    end;

    procedure SetContent(xContent: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Content");
        "Content".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(xContent);
        Modify;
    end;

    procedure GetContent(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        if not Content.HasValue then
            exit('');

        CalcFields("Content");
        "Content".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator));
    end;

    procedure SetErrorLines(xErrorLines: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Error Lines");
        "Error Lines".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(xErrorLines);
        Modify;
    end;

    procedure GetErrorLines(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Error Lines");
        "Error Lines".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator));
    end;

    procedure Export(ShowFileDialog: Boolean)
    var
        DocumentStream: InStream;
        FullFileName: Text;
        IsHandled: Boolean;
    begin
        if (ID = 0) or not Content.HasValue then
            Error('No file available');

        CalcFields(Content);
        FullFileName := StrSubstNo('%1_%2_%3.%4', ID, "Company Name", Format(SystemCreatedAt), FileExtension);
        Content.CreateInStream(DocumentStream);
        DownloadFromStream(DocumentStream, 'Export', '', 'All Files (*.*)|*.*', FullFileName);
    end;

    procedure UpdateLineCount()
    var
        ObjectJSONManagement: Codeunit "JSON Management";
        ArrayJSONManagement: Codeunit "JSON Management";
        JsonObjectAsText, CodeText : Text;
    begin
        JsonObjectAsText := GetContent();
        ObjectJSONManagement.InitializeObject(JsonObjectAsText);
        if not ObjectJSONManagement.GetStringPropertyValueByName('transactions', CodeText) then
            exit;
        ArrayJSONManagement.InitializeCollection(CodeText);
        "No. Lines" := ArrayJSONManagement.GetCollectionCount();
        Modify();
    end;

    var
        FileExtension: Label 'json';
}