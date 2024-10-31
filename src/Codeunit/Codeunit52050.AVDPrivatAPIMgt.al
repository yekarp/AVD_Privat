codeunit 52050 "AVD Privat API Mgt"
{

    Permissions = tabledata "Gen. Journal Line" = rimd;
    trigger OnRun()
    begin
        PrivatOnProcess();
    end;

    internal procedure UploadJsonFile(xAVDPrivatAPILog: Record "AVD Privat API Log")
    var
        InStr: InStream;
        FileName, JsonText : Text;
        TypeHelper: Codeunit "Type Helper";
    begin
        xAVDPrivatAPILog.Content.CreateInStream(InStr, TextEncoding::UTF8);
        if not UploadIntoStream(ChooseJSONFile, '', JSONEXt, FileName, InStr) then Error('');

        JsonText := TypeHelper.ReadAsTextWithSeparator(InStr, TypeHelper.LFSeparator);
        JSONFormating(JsonText);

        if Page.RunModal(Page::"Bank Account List", BankAccount) <> Action::LookupOK then exit;

        PrivatLogging(JsonText, xAVDPrivatAPILog);
        // AVDPrivatAPILogOnInitInsert(xAVDPrivatAPILog, JsonText);
    end;

    internal procedure GenJnlLineOnPost(xBankAccNo: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLinePost: Record "Gen. Journal Line";
        ErrorText: Text;
    begin
        Commit();
        GetAVDPrivatAPISetup(xBankAccNo);
        AVDPrivatAPISetupLine.TestField("Bank Jnl. Template");
        AVDPrivatAPISetupLine.TestField("Bank Jnl. for Customer");

        GenJnlLine.SetRange("Journal Template Name", AVDPrivatAPISetupLine."Bank Jnl. Template");
        GenJnlLine.SetRange("Journal Batch Name", AVDPrivatAPISetupLine."Bank Jnl. for Customer");
        GenJnlLine.SetFilter("SMA Payment Order Status", '<>%1', Enum::"SMA Payment Order Status"::"Error");
        if GenJnlLine.FindSet() then
            repeat
                Clear(ErrorText);
                GenJnlLinePost.Copy(GenJnlLine);
                GenJnlLinePost.SetRange("Line No.", GenJnlLine."Line No.");
                if not PostRunWithCheck(GenJnlLinePost, ErrorText) then begin
                    GenJnlLine."SMA Payment Order Status" := GenJnlLine."SMA Payment Order Status"::Error;
                    GenJnlLine."AVD Error Text" := ErrorText;
                    GenJnlLine.Modify();
                end;
                Commit();
            until GenJnlLine.Next() = 0;
    end;

    [TryFunction]
    procedure GetNextPage(xAVDPrivatAPILog: Record "AVD Privat API Log"; var xNextPageURI: Text; var xNextPageExist: Boolean)
    var
        ObjectJSONManagement: Codeunit "JSON Management";
        xJSONContent: Text;
        CodeText: Text;
    begin
        Clear(xNextPageExist);
        Clear(xNextPageURI);

        xJSONContent := xAVDPrivatAPILog.GetContent();
        ObjectJSONManagement.InitializeObject(xJSONContent);

        if ObjectJSONManagement.GetStringPropertyValueByName('exist_next_page', CodeText) then
            Evaluate(xNextPageExist, CodeText);

        if ObjectJSONManagement.GetStringPropertyValueByName('next_page_id', CodeText) then
            xNextPageURI := CodeText;
    end;

    procedure GenJnlLineOnInsert(var xAVDPrivatAPILog: Record "AVD Privat API Log"; xTestMode: Boolean)
    var
        tempGenJnlLine: Record "Gen. Journal Line" temporary;
        GenJnlLine: Record "Gen. Journal Line";
        LastGenLineNo, WindowCounter, NoLines : Integer;
        LastGenDocNo: Code[20];
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";

        ObjectJSONManagement: Codeunit "JSON Management";
        ArrayJSONManagement: Codeunit "JSON Management";
        ArrayCounter: Integer;
        xJSONContent: Text;
        CodeText, LastError : Text;
        ErrorJsonArray: JsonArray;
    begin
        GetAVDPrivatAPISetup(xAVDPrivatAPILog."Bank Acc. No.");

        AVDPrivatAPISetup.TestField("Show Dialog No. Lines");
        AVDPrivatAPISetup.TestField("Update Dialog No. Lines");

        xJSONContent := xAVDPrivatAPILog.GetContent();
        ObjectJSONManagement.InitializeObject(xJSONContent);

        if not ObjectJSONManagement.GetStringPropertyValueByName('status', CodeText)
        and (CodeText <> 'SUCCESS') then
            CreateErrorArrayJson(ErrorJsonArray, CodeText, 'Status ''SUCCESS'' is missing');

        if not ObjectJSONManagement.GetStringPropertyValueByName('type', CodeText)
        and (CodeText <> 'transactions') then
            CreateErrorArrayJson(ErrorJsonArray, CodeText, 'Type ''transactions'' is missing');

        if not ObjectJSONManagement.GetStringPropertyValueByName('transactions', CodeText) then
            CreateErrorArrayJson(ErrorJsonArray, CodeText, 'Transactions area is missing');

        xJSONContent := CodeText;
        AlreadyExistCounter := 0;

        // if error is exist then nothing do
        if ErrorJsonArray.Count = 0 then begin
            ArrayJSONManagement.InitializeCollection(xJSONContent);
            NoLines := ArrayJSONManagement.GetCollectionCount();

            if ShowDialog(NoLines, AVDPrivatAPISetup."Show Dialog No. Lines") then
                Window.Open(StrSubstNo(Text005, AVDPrivatAPISetupLine."Bank Jnl. Template") + Text006 + Text007);

            Clear(WindowCounter);

            // Lock Tables before create
            GenJnlLine.LockTable();

            // create temp records
            for ArrayCounter := 0 to ArrayJSONManagement.GetCollectionCount() - 1 do begin
                Clear(CodeText);
                ArrayJSONManagement.GetObjectFromCollectionByIndex(CodeText, ArrayCounter);

                WindowCounter += 1;
                if ShowDialog(NoLines, AVDPrivatAPISetup."Show Dialog No. Lines") and UpdateDialog(WindowCounter, AVDPrivatAPISetup."Update Dialog No. Lines") then
                    Window.Update(1, StrSubstNo(Text010, WindowCounter, NoLines));

                if not TempGenJnlLineFromJsonOnInsert(tempGenJnlLine, CodeText, LastGenLineNo, LastGenDocNo, LastError) then
                    CreateErrorArrayJson(ErrorJsonArray, CodeText, LastError);
            end;

            if ShowDialog(NoLines, AVDPrivatAPISetup."Show Dialog No. Lines") then
                Window.Update(1, lblDone);

            Clear(WindowCounter);
            tempGenJnlLine.Reset();
            NoLines := tempGenJnlLine.Count;

            // Commit();
            // Page.RunModal(Page::"AVD Gen.Jnl.Lines", tempGenJnlLine);

            // create records gen. jnl. line
            if tempGenJnlLine.FindSet() then
                repeat
                    WindowCounter += 1;
                    if ShowDialog(NoLines, AVDPrivatAPISetup."Show Dialog No. Lines") and UpdateDialog(WindowCounter, AVDPrivatAPISetup."Update Dialog No. Lines") then
                        Window.Update(2, StrSubstNo(Text010, WindowCounter, NoLines));

                    GenJnlLine := tempGenJnlLine;
                    GetNewGenJnlLineNo(GenJnlLine);
                    GenJnlLine.Insert(true);
                until tempGenJnlLine.Next() = 0;

            if ShowDialog(NoLines, AVDPrivatAPISetup."Show Dialog No. Lines") then
                Window.Update(2, lblDone);

            if ShowDialog(NoLines, AVDPrivatAPISetup."Show Dialog No. Lines") then
                Window.Close();
        end;

        ErrorJsonArray.WriteTo(CodeText);
        ArrayJSONManagement.InitializeCollection(CodeText);
        CodeText := ArrayJSONManagement.WriteCollectionToString();

        xAVDPrivatAPILog.SetErrorLines(CodeText);
        xAVDPrivatAPILog."Last Error" := '';
        xAVDPrivatAPILog."No. Error Lines" := 0;
        xAVDPrivatAPILog."Without Dupl. No. Error Lines" := 0;

        if ErrorJsonArray.Count <> 0 then begin
            xAVDPrivatAPILog."No. Error Lines" := ErrorJsonArray.Count;
            xAVDPrivatAPILog."Without Dupl. No. Error Lines" := xAVDPrivatAPILog."No. Error Lines" - AlreadyExistCounter;
            xAVDPrivatAPILog."Last Error" := GetLastErrorCallStack();
        end;

        if xTestMode then
            xAVDPrivatAPILog."Active" := false;

        // xAVDPrivatAPILog.Modify();
    end;

    local procedure JSONFormating(var JsonText: Text)
    var
        JsonObject: JsonObject;
        ObjectJSONManagement: Codeunit "JSON Management";
    begin
        ObjectJSONManagement.InitializeObject(JsonText);
        JsonText := ObjectJSONManagement.WriteObjectToString();
    end;

    local procedure GetAVDPrivatAPISetup(xBankAccNo: Code[20])
    begin
        if not AVDPrivatAPISetupRead then begin
            AVDPrivatAPISetupRead := true;
            AVDPrivatAPISetup.Reset();
            if not AVDPrivatAPISetup.Get() then begin
                AVDPrivatAPISetup.Init();
                AVDPrivatAPISetup.Insert();
            end;
        end;

        if AVDPrivatAPISetupLine."Bank Acc. No." <> xBankAccNo then
            if not AVDPrivatAPISetupLine.Get(xBankAccNo) then begin
                AVDPrivatAPISetupLine.Reset();
                if AVDPrivatAPISetupLine.FindLast() then
                    AVDPrivatAPISetupLine := AVDPrivatAPISetupLine;
                AVDPrivatAPISetupLine."Bank Acc. No." := xBankAccNo;
                AVDPrivatAPISetupLine.Insert();
            end;

        AVDPrivatAPISetupLine.TestField("Bank Acc. No.");
        if BankAccount."No." <> xBankAccNo then
            GetBankAccount(AVDPrivatAPISetupLine."Bank Acc. No.");
    end;

    local procedure ShowDialog(xNoLines: Integer; xMinNoLines: Integer): Boolean
    begin
        exit(xNoLines > xMinNoLines);
    end;

    local procedure UpdateDialog(xNoLine: Integer; xUpdateNoLines: Integer): Boolean
    begin
        exit(xNoLine mod xUpdateNoLines = 0);
    end;

    local procedure TempGenJnlLineFromJsonOnInsert(var tempGenJnlLine: Record "Gen. Journal Line" temporary;
                                                        xJsonObjectText: Text;
                                                        var LastLineNo: Integer; var LastDocNo: Code[20];
                                                        var xLastError: Text): Boolean
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        AccountType: Enum "Gen. Journal Account Type";
        SourceType: Enum "Gen. Journal Source Type";
        ObjectJSONManagement: Codeunit "JSON Management";
        CodeText, RegistrationNumber, LoginID : Text;
        AgreementMandatory: Boolean;
        IsHandled: Boolean;
        CounterTrue: Integer;
        ErrorText: Text;
        Customer: Record Customer;
        SalesPerson: Record "Salesperson/Purchaser";
        DimensionSetIDArr: array[10] of Integer;
    begin
        IsHandled := false;
        OnBeforeInsertTempGenJnlLineFromJson(tempGenJnlLine, xJsonObjectText, IsHandled);
        if IsHandled then
            exit;

        CounterTrue := 0;
        ObjectJSONManagement.InitializeObject(xJsonObjectText);

        if ObjectJSONManagement.GetStringPropertyValueByName('DOC_TYP', CodeText) then
            if CodeText <> 'j' then CounterTrue += 1;

        if ObjectJSONManagement.GetStringPropertyValueByName('FL_REAL', CodeText) then
            if CodeText = 'r' then CounterTrue += 1;

        if ObjectJSONManagement.GetStringPropertyValueByName('TRANTYPE', CodeText) then
            if not (CodeText in ['C', 'D']) then
                Error(lblUndefinedJournalType, CodeText);

        if CodeText = 'C' then CounterTrue += 1;

        tempGenJnlLine.Init();
        case true of
            CodeText = 'D':
                begin
                    AVDPrivatAPISetupLine.TestField("Bank Jnl. Template");
                    AVDPrivatAPISetupLine.TestField("Bank Jnl. for Vendor");
                    tempGenJnlLine.Validate("Journal Template Name", AVDPrivatAPISetupLine."Bank Jnl. Template");
                    tempGenJnlLine.Validate("Journal Batch Name", AVDPrivatAPISetupLine."Bank Jnl. for Vendor");
                    tempGenJnlLine.Validate("Account Type", tempGenJnlLine."Account Type"::Vendor);
                end;
            CounterTrue = 3:
                begin
                    AVDPrivatAPISetupLine.TestField("Bank Jnl. Template");
                    AVDPrivatAPISetupLine.TestField("Bank Jnl. for Customer");
                    tempGenJnlLine.Validate("Journal Template Name", AVDPrivatAPISetupLine."Bank Jnl. Template");
                    tempGenJnlLine.Validate("Journal Batch Name", AVDPrivatAPISetupLine."Bank Jnl. for Customer");
                    tempGenJnlLine.Validate("Account Type", tempGenJnlLine."Account Type"::Customer);
                end;
            else begin
                exit;
            end;
        end;

        tempGenJnlLine.Validate("Document Type", tempGenJnlLine."Document Type"::Payment);

        if ObjectJSONManagement.GetStringPropertyValueByName('ID', CodeText) then
            tempGenJnlLine.Validate("Document No.", CodeText);

        if ObjectJSONManagement.GetStringPropertyValueByName('DAT_OD', CodeText) then
            tempGenJnlLine.Validate("Posting Date", ConvertTxt2Date(CodeText));

        if AVDPrivatAPISetup."Duplicate Posted Entry"
        and (tempGenJnlLine."Document No." <> '')
        and (tempGenJnlLine."Posting Date" <> 0D) then
            if not CheckDuplicatePostedDocumentNoPostingDate(tempGenJnlLine) then begin// пошук облікованого документу
                xLastError := GetLastErrorText();
                exit(false);
            end;

        if ObjectJSONManagement.GetStringPropertyValueByName('NUM_DOC', CodeText) then
            tempGenJnlLine.Validate("External Document No.", CopyStr(CodeText, 1, MaxStrLen(tempGenJnlLine."External Document No.")));

        case AVDPrivatAPISetupLine."Owner Organization Form" of
            AVDPrivatAPISetup."Org. form LLC":
                tempGenJnlLine.Validate("Account No.", GetEntityNoLLC(tempGenJnlLine, xJsonObjectText, ErrorText));
            else
                tempGenJnlLine.Validate("Account No.", GetEntityNoIndividualEntrepreneur(tempGenJnlLine, xJsonObjectText, ErrorText));
        end;

        tempGenJnlLine."AVD Error Text" := ErrorText;
        if tempGenJnlLine."AVD Error Text" <> '' then
            tempGenJnlLine."SMA Payment Order Status" := tempGenJnlLine."SMA Payment Order Status"::Error;

        if tempGenJnlLine."Account No." <> '' then
            tempGenJnlLine.Validate("SMA Agreement No.", GetAgreementByEntityNo(tempGenJnlLine));

        if ObjectJSONManagement.GetStringPropertyValueByName('OSND', CodeText) then
            tempGenJnlLine.Validate(Description, CopyStr(CodeText, 1, MaxStrLen(tempGenJnlLine.Description)));

        GenJnlBatch.Get(tempGenJnlLine."Journal Template Name", tempGenJnlLine."Journal Batch Name");
        tempGenJnlLine.Validate("Bal. Account Type", GenJnlBatch."Bal. Account Type");
        tempGenJnlLine.Validate("Bal. Account No.", GenJnlBatch."Bal. Account No.");

        if ObjectJSONManagement.GetStringPropertyValueByName('SUM', CodeText) then
            if tempGenJnlLine."Journal Batch Name" = AVDPrivatAPISetupLine."Bank Jnl. for Vendor" then
                tempGenJnlLine.Validate(Amount, ConvertTxt2Decimal(CodeText))
            else
                tempGenJnlLine.Validate(Amount, -ConvertTxt2Decimal(CodeText));

        if LastLineNo = 0 then
            GetGenJnlLastNo(tempGenJnlLine."Journal Template Name", tempGenJnlLine."Journal Batch Name", LastLineNo, LastDocNo);
        LastLineNo += 10000;
        tempGenJnlLine."Line No." := LastLineNo;

        if not CheckDuplicateDocumentNoPostingDateGenJnlLine(tempGenJnlLine) then begin// пошук необлікованого документу
            xLastError := GetLastErrorText();
            exit(false);
        end;

        if (tempGenJnlLine."Journal Batch Name" = AVDPrivatAPISetupLine."Bank Jnl. for Customer")
        or (tempGenJnlLine."Journal Batch Name" = AVDPrivatAPISetupLine."Bank Jnl. for Analisys") then
            UpdateGenJnlLineDimensionsFromJsonOnInsert(tempGenJnlLine);

        if (tempGenJnlLine."Journal Batch Name" = AVDPrivatAPISetupLine."Bank Jnl. for Customer") then begin
            // update dimensions
            // if AVDPrivatAPISetup."Customer Dimension Value" <> '' then
            // UpdateGenJnlLineDimensionsFromJsonOnInsert(tempGenJnlLine);
            if AVDPrivatAPISetup."Preview Check" then
                if not PreviewRunCheck(tempGenJnlLine) then begin
                    AVDPrivatAPISetupLine.TestField("Bank Jnl. for Analisys");
                    tempGenJnlLine.Validate("Journal Batch Name", AVDPrivatAPISetupLine."Bank Jnl. for Analisys");
                    tempGenJnlLine."AVD Error Text" := GetLastErrorText();
                    if tempGenJnlLine."AVD Error Text" <> '' then
                        tempGenJnlLine."SMA Payment Order Status" := tempGenJnlLine."SMA Payment Order Status"::Error;
                end;
            // else
            //     if AVDPrivatAPISetup."Post Line" then begin
            //         if not PostRunWithCheck(tempGenJnlLine, ErrorText) then
            //             exit;
            //         tempGenJnlLine.Validate("Journal Batch Name", AVDPrivatAPISetup."Bank Jnl. for Analisys");
            //         tempGenJnlLine."AVD Error Text" := ErrorText;
            //         if tempGenJnlLine."AVD Error Text" <> '' then
            //             tempGenJnlLine."SMA Payment Order Status" := tempGenJnlLine."SMA Payment Order Status"::Error;
            //     end;
        end;

        tempGenJnlLine.Insert(true);

        LastDocNo := tempGenJnlLine."Document No.";
        xLastError := tempGenJnlLine."AVD Error Text";
        exit(xLastError = '');
    end;

    local procedure UpdateGenJnlLineDimensionsFromJsonOnInsert(var xtempGenJnlLine: Record "Gen. Journal Line" temporary)
    var
        tempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        AVDPrivatDims: Record "AVD Privat Dimension";
    begin
        AVDPrivatDims.SetRange("Bank Acc. No.", BankAccount."No.");
        AVDPrivatDims.SetRange(Blocked, false);
        if AVDPrivatDims.IsEmpty then exit;

        DimMgt.GetDimensionSet(tempDimensionSetEntry, xtempGenJnlLine."Dimension Set ID");
        AVDPrivatDims.FindSet();
        repeat
            tempDimensionSetEntry.SetRange("Dimension Code", AVDPrivatDims."Income Dimension Code");
            if tempDimensionSetEntry.FindFirst() then begin
                if (tempDimensionSetEntry."Dimension Value Code" <> AVDPrivatDims."Income Dimension Value") then begin
                    tempDimensionSetEntry.Validate("Dimension Value Code", AVDPrivatDims."Income Dimension Value");
                    tempDimensionSetEntry.Modify();
                end;
            end else begin
                tempDimensionSetEntry.Init();
                tempDimensionSetEntry.Validate("Dimension Code", AVDPrivatDims."Income Dimension Code");
                tempDimensionSetEntry.Validate("Dimension Value Code", AVDPrivatDims."Income Dimension Value");
                tempDimensionSetEntry.Insert();
            end;
        until AVDPrivatDims.Next() = 0;
        tempDimensionSetEntry.Reset();
        UpdateGenJnlLineGlobalDimensionsFromDimensionSetEntry(xtempGenJnlLine, tempDimensionSetEntry);

        // tempDimensionSetEntry.SetRange("Dimension Code", AVDPrivatAPISetup."Customer Dimension Code");
        // if tempDimensionSetEntry.FindFirst() then
        //     if (tempDimensionSetEntry."Dimension Value Code" <> AVDPrivatAPISetup."Customer Dimension Value") then begin
        //         tempDimensionSetEntry.Validate("Dimension Value Code", AVDPrivatAPISetup."Customer Dimension Value");
        //         tempDimensionSetEntry.Modify();
        //         tempDimensionSetEntry.Reset();
        //         UpdateGenJnlLineGlobalDimensionsFromDimensionSetEntry(xtempGenJnlLine, tempDimensionSetEntry);
        //         exit;
        //     end else
        //         exit;

        // tempDimensionSetEntry.Init();
        // tempDimensionSetEntry.Validate("Dimension Code", AVDPrivatAPISetup."Customer Dimension Code");
        // tempDimensionSetEntry.Validate("Dimension Value Code", AVDPrivatAPISetup."Customer Dimension Value");
        // tempDimensionSetEntry.Insert();
        // tempDimensionSetEntry.Reset();
        // UpdateGenJnlLineGlobalDimensionsFromDimensionSetEntry(xtempGenJnlLine, tempDimensionSetEntry);
    end;

    local procedure UpdateGenJnlLineGlobalDimensionsFromDimensionSetEntry(var xtempGenJnlLine: Record "Gen. Journal Line" temporary; var xtempDimensionSetEntry: Record "Dimension Set Entry" temporary)

    begin
        xtempGenJnlLine."Dimension Set ID" := DimMgt.GetDimensionSetID(xtempDimensionSetEntry);
        DimMgt.UpdateGlobalDimFromDimSetID(xtempGenJnlLine."Dimension Set ID",
                                            xtempGenJnlLine."Shortcut Dimension 1 Code",
                                            xtempGenJnlLine."Shortcut Dimension 2 Code");
    end;

    local procedure CreateErrorArrayJson(var xErrorJsonArray: JsonArray; xErrorJsonText: Text; xErrorText: Text)
    var
        ErrorJsonObject: JsonObject;
    begin
        if StrPos(xErrorText, AlreadyExistLbl) <> 0 then
            AlreadyExistCounter += 1;
        ErrorJsonObject.ReadFrom(xErrorJsonText);
        ErrorJsonObject.Add('Error', xErrorText);

        xErrorJsonArray.Add(ErrorJsonObject);
    end;

    procedure GetGenJnlLastNo(xJournalTemplateName: Code[10]; xJournalBatchName: Code[10]; var xLastLineNo: Integer; var xLastDocNo: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Clear(xLastLineNo);
        Clear(xLastDocNo);

        GenJnlLine.SetRange("Journal Template Name", xJournalTemplateName);
        GenJnlLine.SetRange("Journal Batch Name", xJournalBatchName);
        if GenJnlLine.FindLast() then begin
            xLastLineNo := GenJnlLine."Line No.";
            xLastDocNo := GenJnlLine."Document No.";
        end;
    end;

    [TryFunction]
    local procedure CheckDuplicatePostedDocumentNoPostingDate(var xtempGenJnlLine: Record "Gen. Journal Line" temporary)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Document Type", "Document No.", "Posting Date", Reversed);
        GLEntry.SetRange("Document Type", xtempGenJnlLine."Document Type");
        GLEntry.SetRange("Document No.", xtempGenJnlLine."Document No.");
        GLEntry.SetRange("Posting Date", xtempGenJnlLine."Posting Date");
        GLEntry.SetRange(Reversed, false);
        if GLEntry.IsEmpty then exit;
        Error(errPostedDocumentFound, xtempGenJnlLine."Document Type", xtempGenJnlLine."Document No.", xtempGenJnlLine."Posting Date");
    end;

    local procedure GetEntityNoLLC(var xtempGenJnlLine: Record "Gen. Journal Line" temporary; xJsonObjectText: Text; var xErrorText: Text): Code[20]
    var
        CustomerByRegNo: Record Customer;
        CustomerByLoginID: Record Customer;
        CustAgr: Record "SMA Customer Agreement";
        Vendor: Record Vendor;
        ObjectJSONManagement: Codeunit "JSON Management";
        RegEx: Codeunit Regex;
        Matches: Record Matches temporary;
        CodeText: Text;
        LoginID: Text;
        PaymentAssignment: Text;
    // errCantFindCustomerByLoginID: Label 'Can`t Find Customer By Login ID %1';
    // errCantFindLoginIDInPaymentAssignment: Label 'Can`t Find Login ID in Payment Assignment %1';
    // errCantFindAssinedPayment: Label 'Can`t Find Assined Payment';
    // errCantFindVendorByRegistrationNumber: Label 'Can`t Find Vendor By %1 %2';
    // errCantFindCustomerByRegistrationNumber: Label 'Can`t Find Customer By %1 %2';
    // errCantFindEDRPOU: Label 'Can`t Find EDRPOU in %1';
    // errIncorrectPaymentForOwnership: Label 'Incorrect payment for ownership %1';
    begin
        AVDPrivatAPISetup.TestField("RegEx Pattern");
        AVDPrivatAPISetupLine.TestField("Bank Jnl. for Analisys");
        AVDPrivatAPISetup.TestField("Privat Registration No.");

        Clear(xErrorText);
        Clear(PaymentAssignment);

        ObjectJSONManagement.InitializeObject(xJsonObjectText);
        if ObjectJSONManagement.GetStringPropertyValueByName('OSND', CodeText) then begin
            PaymentAssignment := CodeText;
            xtempGenJnlLine.Validate(Description, CopyStr(CodeText, 1, MaxStrLen(xtempGenJnlLine.Description)));
            xtempGenJnlLine.Validate("SMA Payment Assignment", CopyStr(CodeText, 1, MaxStrLen(xtempGenJnlLine."SMA Payment Assignment")));
        end;

        if ObjectJSONManagement.GetStringPropertyValueByName('AUT_CNTR_CRF', CodeText) then
            case xtempGenJnlLine."Account Type" of
                xtempGenJnlLine."Account Type"::Customer:
                    begin
                        // EDRPOU Bank
                        if CodeText = AVDPrivatAPISetup."Privat Registration No." then begin
                            if PaymentAssignment <> '' then begin
                                RegEx.Match(PaymentAssignment, AVDPrivatAPISetup."RegEx Pattern", Matches);
                                if Matches.FindFirst() then begin
                                    LoginID := CopyStr(PaymentAssignment, Matches.Index + 1, Matches.Length);
                                    if CustomerByLoginID.Get(LoginID) then begin
                                        if CustomerByLoginID."SMA Organization Form" = AVDPrivatAPISetup."Org. form LLC" then begin
                                            xtempGenJnlLine.Validate("Journal Batch Name", AVDPrivatAPISetupLine."Bank Jnl. for Analisys");
                                            xErrorText := StrSubstNo(errIncorrectPaymentForOwnership, AVDPrivatAPISetup."Org. form LLC");
                                        end;

                                        exit(CustomerByLoginID."No.");
                                    end else begin
                                        xtempGenJnlLine.Validate("Journal Batch Name", AVDPrivatAPISetupLine."Bank Jnl. for Analisys");
                                        xErrorText := StrSubstNo(errCantFindCustomerByLoginID, LoginID);
                                        exit(CustomerByLoginID."No.");
                                    end;
                                end else begin
                                    xtempGenJnlLine.Validate("Journal Batch Name", AVDPrivatAPISetupLine."Bank Jnl. for Analisys");
                                    xErrorText := StrSubstNo(errCantFindLoginIDInPaymentAssignment, PaymentAssignment);
                                    exit(CustomerByLoginID."No.");
                                end;
                            end else begin
                                xtempGenJnlLine.Validate("Journal Batch Name", AVDPrivatAPISetupLine."Bank Jnl. for Analisys");
                                xErrorText := StrSubstNo(errCantFindAssinedPayment);
                                exit(CustomerByLoginID."No.");
                            end;
                        end;

                        // EDRPOU another contragent
                        // CustomerByRegNo.SetCurrentKey("SMA EDRPOU Code");
                        // CustomerByRegNo.SetFilter("SMA EDRPOU Code", CodeText);
                        CustomerByRegNo.SetCurrentKey("Registration Number");
                        CustomerByRegNo.SetFilter("Registration Number", CodeText);
                        if CustomerByRegNo.FindFirst() then begin
                            if PaymentAssignment <> '' then begin
                                RegEx.Match(PaymentAssignment, AVDPrivatAPISetup."RegEx Pattern", Matches);
                                if Matches.FindFirst() then begin
                                    LoginID := CopyStr(PaymentAssignment, Matches.Index + 1, Matches.Length);
                                    if CustomerByLoginID.Get(LoginID) then begin
                                        if CustomerByRegNo."No." = CustomerByLoginID."No." then begin
                                            if CustomerByRegNo."SMA Organization Form" = AVDPrivatAPISetup."Org. form F2" then begin
                                                xtempGenJnlLine.Validate("Journal Batch Name", AVDPrivatAPISetupLine."Bank Jnl. for Analisys");
                                                xErrorText := StrSubstNo(errIncorrectPaymentForOwnership, AVDPrivatAPISetup."Org. form F2");
                                            end;

                                            exit(CustomerByRegNo."No.");
                                        end else begin
                                            xtempGenJnlLine.Validate("Journal Batch Name", AVDPrivatAPISetupLine."Bank Jnl. for Analisys");
                                            xErrorText := StrSubstNo(errCantFindCustomerByLoginID, LoginID);
                                            exit(CustomerByRegNo."No.");
                                        end;
                                    end else begin
                                        xtempGenJnlLine.Validate("Journal Batch Name", AVDPrivatAPISetupLine."Bank Jnl. for Analisys");
                                        xErrorText := StrSubstNo(errCantFindCustomerByLoginID, LoginID);
                                        exit(CustomerByRegNo."No.");
                                    end;
                                end else begin
                                    if CustomerByRegNo."SMA Organization Form" = AVDPrivatAPISetup."Org. form F2" then begin
                                        xtempGenJnlLine.Validate("Journal Batch Name", AVDPrivatAPISetupLine."Bank Jnl. for Analisys");
                                        xErrorText := StrSubstNo(errIncorrectPaymentForOwnership, AVDPrivatAPISetup."Org. form F2");
                                    end;
                                    exit(CustomerByRegNo."No.");
                                end;
                            end else begin
                                xtempGenJnlLine.Validate("Journal Batch Name", AVDPrivatAPISetupLine."Bank Jnl. for Analisys");
                                xErrorText := StrSubstNo(errCantFindAssinedPayment);
                                exit(CustomerByRegNo."No.");
                            end;
                        end else begin
                            xtempGenJnlLine.Validate("Journal Batch Name", AVDPrivatAPISetupLine."Bank Jnl. for Analisys");
                            // xErrorText := StrSubstNo(errCantFindCustomerByRegistrationNumber, CustomerByRegNo.FieldCaption("SMA EDRPOU Code"), CodeText);
                            xErrorText := StrSubstNo(errCantFindCustomerByRegistrationNumber, CustomerByRegNo.FieldCaption("Registration Number"), CodeText);
                            exit('');
                        end;
                    end;
                xtempGenJnlLine."Account Type"::Vendor:
                    begin
                        // Vendor.SetCurrentKey("SMA EDRPOU Code");
                        // Vendor.SetFilter("SMA EDRPOU Code", CodeText);
                        Vendor.SetCurrentKey("Registration Number");
                        Vendor.SetFilter("Registration Number", CodeText);
                        if Vendor.FindFirst() then
                            exit(Vendor."No.");

                        // xErrorText := StrSubstNo(errCantFindVendorByRegistrationNumber, Vendor.FieldCaption("SMA EDRPOU Code"), CodeText);
                        xErrorText := StrSubstNo(errCantFindVendorByRegistrationNumber, Vendor.FieldCaption("Registration Number"), CodeText);
                        exit('');
                    end;
            end;

        xtempGenJnlLine.Validate("Journal Batch Name", AVDPrivatAPISetupLine."Bank Jnl. for Analisys");
        xErrorText := StrSubstNo(errCantFindEDRPOU, xJsonObjectText);
        exit('');
    end;

    local procedure GetEntityNoIndividualEntrepreneur(var xtempGenJnlLine: Record "Gen. Journal Line" temporary; xJsonObjectText: Text; var xErrorText: Text): Code[20]
    var
        CustomerByRegNo: Record Customer;
        CustomerByLoginID: Record Customer;
        CustAgr: Record "SMA Customer Agreement";
        Vendor: Record Vendor;
        ObjectJSONManagement: Codeunit "JSON Management";
        RegEx: Codeunit Regex;
        Matches: Record Matches temporary;
        CodeText: Text;
        LoginID: Text;
        PaymentAssignment: Text;
    // errCantFindCustomerByLoginID: Label 'Can`t Find Customer By Login ID %1';
    // errCantFindLoginIDInPaymentAssignment: Label 'Can`t Find Login ID in Payment Assignment %1';
    // errCantFindAssinedPayment: Label 'Can`t Find Assined Payment';
    // errCantFindVendorByRegistrationNumber: Label 'Can`t Find Vendor By %1 %2';
    // errCantFindCustomerByRegistrationNumber: Label 'Can`t Find Customer By %1 %2';
    // errCantFindEDRPOU: Label 'Can`t Find EDRPOU in %1';
    // errIncorrectPaymentForOwnership: Label 'Incorrect payment for ownership %1';
    begin
        AVDPrivatAPISetup.TestField("RegEx Pattern");
        AVDPrivatAPISetupLine.TestField("Bank Jnl. for Analisys");
        AVDPrivatAPISetup.TestField("Privat Registration No.");

        Clear(xErrorText);
        Clear(PaymentAssignment);

        ObjectJSONManagement.InitializeObject(xJsonObjectText);
        if ObjectJSONManagement.GetStringPropertyValueByName('OSND', CodeText) then begin
            PaymentAssignment := CodeText;
            xtempGenJnlLine.Validate(Description, CopyStr(CodeText, 1, MaxStrLen(xtempGenJnlLine.Description)));
            xtempGenJnlLine.Validate("SMA Payment Assignment", CopyStr(CodeText, 1, MaxStrLen(xtempGenJnlLine."SMA Payment Assignment")));
        end;

        if ObjectJSONManagement.GetStringPropertyValueByName('AUT_CNTR_CRF', CodeText) then
            case xtempGenJnlLine."Account Type" of
                xtempGenJnlLine."Account Type"::Customer:
                    begin
                        // EDRPOU Bank
                        if CodeText = AVDPrivatAPISetup."Privat Registration No." then
                            if PaymentAssignment <> '' then begin
                                RegEx.Match(PaymentAssignment, AVDPrivatAPISetup."RegEx Pattern", Matches);
                                if Matches.FindFirst() then begin
                                    LoginID := CopyStr(PaymentAssignment, Matches.Index + 1, Matches.Length);
                                    if CustomerByLoginID.Get(LoginID) then begin
                                        if CustomerByLoginID."SMA Organization Form" = AVDPrivatAPISetup."Org. form F2" then
                                            exit(CustomerByLoginID."No.");
                                    end else begin
                                        xtempGenJnlLine.Validate("Journal Batch Name", AVDPrivatAPISetupLine."Bank Jnl. for Analisys");
                                        xErrorText := StrSubstNo(errCantFindCustomerByLoginID, LoginID);
                                        exit(CustomerByLoginID."No.");
                                    end;
                                end else begin
                                    xtempGenJnlLine.Validate("Journal Batch Name", AVDPrivatAPISetupLine."Bank Jnl. for Analisys");
                                    xErrorText := StrSubstNo(errCantFindLoginIDInPaymentAssignment, PaymentAssignment);
                                    exit(CustomerByLoginID."No.");
                                end;
                            end else begin
                                xtempGenJnlLine.Validate("Journal Batch Name", AVDPrivatAPISetupLine."Bank Jnl. for Analisys");
                                xErrorText := StrSubstNo(errCantFindAssinedPayment);
                                exit(CustomerByLoginID."No.");
                            end;
                    end;
                xtempGenJnlLine."Account Type"::Vendor:
                    begin
                        // Vendor.SetCurrentKey("SMA EDRPOU Code");
                        // Vendor.SetFilter("SMA EDRPOU Code", CodeText);
                        Vendor.SetCurrentKey("Registration Number");
                        Vendor.SetFilter("Registration Number", CodeText);
                        if Vendor.FindFirst() then
                            exit(Vendor."No.");

                        // xErrorText := StrSubstNo(errCantFindVendorByRegistrationNumber, Vendor.FieldCaption("SMA EDRPOU Code"), CodeText);
                        xErrorText := StrSubstNo(errCantFindVendorByRegistrationNumber, Vendor.FieldCaption("Registration Number"), CodeText);
                        exit('');
                    end;
            end;

        xtempGenJnlLine.Validate("Journal Batch Name", AVDPrivatAPISetupLine."Bank Jnl. for Analisys");
        xErrorText := StrSubstNo(errCantFindEDRPOU, xJsonObjectText);
        exit('');
    end;

    [TryFunction]
    local procedure CheckDuplicateDocumentNoPostingDateGenJnlLine(var xtempGenJnlLine: Record "Gen. Journal Line" temporary)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", xtempGenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", xtempGenJnlLine."Journal Batch Name");
        GenJnlLine.SetRange("Document No.", xtempGenJnlLine."Document No.");
        if not GenJnlLine.IsEmpty then
            Error(errDocumentAlreadyExist, xtempGenJnlLine."Document Type", xtempGenJnlLine."Document No.", xtempGenJnlLine."Posting Date");
    end;

    local procedure GetAgreementByEntityNo(var xtempGenJnlLine: Record "Gen. Journal Line" temporary): Code[20]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        CustAgrmt: Record "SMA Customer Agreement";
        VendAgrmt: Record "SMA Vendor Agreement";
    begin
        case xtempGenJnlLine."Account Type" of
            xtempGenJnlLine."Account Type"::Customer:
                begin
                    if not Customer.Get(xtempGenJnlLine."Account No.")
                    or (Customer."SMA Agreement Posting" <> Customer."SMA Agreement Posting"::Mandatory) then
                        exit('');

                    CustAgrmt.SetRange("Customer No.", Customer."No.");
                    CustAgrmt.SetRange(Active, true);
                    CustAgrmt.SetRange("Default Agreement", true);
                    if CustAgrmt.FindSet() then
                        repeat
                            exit(CustAgrmt."No.");
                        until CustAgrmt.Next() = 0;
                end;

            xtempGenJnlLine."Account Type"::Vendor:
                begin
                    if not Vendor.Get(xtempGenJnlLine."Account No.")
                                        or (Vendor."SMA Agreement Posting" <> Vendor."SMA Agreement Posting"::Mandatory) then
                        exit('');

                    VendAgrmt.SetRange("Vendor No.", Vendor."No.");
                    VendAgrmt.SetRange(Active, true);
                    VendAgrmt.SetRange("Default Agreement", true);
                    VendAgrmt.SetRange("Global Dimension 2 Code", AVDPrivatAPISetup."Global Dimension 2 Code");
                    if VendAgrmt.FindSet() then
                        repeat
                            exit(VendAgrmt."No.");
                        until VendAgrmt.Next() = 0;
                end;
        end;
        exit('');
    end;

    local procedure GetCurrencyCodeByBatchTemplate(var xtempGenJnlLine: Record "Gen. Journal Line" temporary): Code[10]
    var
        GenJournalBatch: record "Gen. Journal Batch";
        BankAcc: Record "Bank Account";
    begin
        if not GenJournalBatch.Get(xtempGenJnlLine."Journal Template Name", xtempGenJnlLine."Journal Batch Name") then exit('');

        if BankAcc.Get(GenJournalBatch."Bal. Account No.") then
            exit(BankAcc."Currency Code");
        exit('');
    end;

    procedure ConvertTxt2Decimal(xText: Text): Decimal
    var
        lblCharactersToKeep: Label '1234567890.,-', Locked = true;
        lblComma: Label ',', Locked = true;
        lblDot: Label '.', Locked = true;
        txtValue: Text;
        decValue: Decimal;
        PosComma: Integer;
        PosDot: Integer;
    begin
        txtValue := DelChr(xText, '=', DelChr(xText, '=', lblCharactersToKeep));
        PosComma := StrPos(txtValue, lblComma);
        PosDot := StrPos(txtValue, lblDot);

        case true of
            (PosComma > 0) and (PosDot > 0):
                begin
                    case true of
                        (PosComma > PosDot):
                            begin
                                txtValue := txtValue.Replace(lblDot, '');
                                txtValue := txtValue.Replace(lblComma, lblDot);
                            end;
                        else
                            txtValue := txtValue.Replace(lblComma, '');
                    end;
                end;
            (PosComma > 0):
                begin
                    txtValue := txtValue.Replace(lblComma, lblDot);
                end;
        end;

        if not Evaluate(decValue, txtValue, 9) then
            Evaluate(decValue, txtValue, 10);

        exit(decValue);
    end;

    procedure ConvertTxt2Date(xText: Text): Date
    var
        lblCharactersToKeep: Label '1234567890', Locked = true;
        txtSplitter: Text;
        dateValue: Date;
        dtValue: DateTime;
        lblSpace: Label ' ', Locked = true;
        lblCharT: Label 'T', Locked = true;
        DateParts: List of [Text];
        Year: Integer;
        Month: Integer;
        Day: Integer;
    begin
        // convert Ukraine date time to date
        if StrPos(xText, lblSpace) <> 0 then begin
            xText := CopyStr(xText, 1, StrPos(xText, lblSpace) - 1);
            txtSplitter := DelChr(xText, '=', lblCharactersToKeep);
            DateParts := xText.Split(txtSplitter[1]);
            Evaluate(Day, DateParts.Get(1));
            Evaluate(Month, DateParts.Get(2));
            Evaluate(Year, DateParts.Get(3));
            dateValue := DMY2Date(Day, Month, Year);
            exit(dateValue);
        end;

        // convert XML date time to date
        if StrPos(xText, lblCharT) <> 0 then begin
            xText := CopyStr(xText, 1, StrPos(xText, lblCharT) - 1);
            txtSplitter := DelChr(xText, '=', lblCharactersToKeep);
            DateParts := xText.Split(txtSplitter[1]);
            Evaluate(Day, DateParts.Get(3));
            Evaluate(Month, DateParts.Get(2));
            Evaluate(Year, DateParts.Get(1));
            dateValue := DMY2Date(Day, Month, Year);
            exit(dateValue);
        end;

        // standart convert
        Evaluate(dateValue, xText);
        exit(dateValue);
    end;

    procedure PrivatTransactionsOnGet(xIBAN: Code[50]; xAllStatistic: Boolean): Boolean
    var
        AVDPrivatAPILog: Record "AVD Privat API Log";
        Parameters: Text;
        Response: Text;
        NextPageURI: Text;
        NextPageExist: Boolean;
        xURLTxt, URLTxt : Text;
        IsSuccessStatus: Boolean;
    begin
        // Setup the URL
        AVDPrivatAPISetupLine.TestField("Bank Acc. No.");
        GetAVDPrivatAPISetup(AVDPrivatAPISetupLine."Bank Acc. No.");
        AVDPrivatAPISetup.TestField("API Url");
        AVDPrivatAPISetup.TestField("Limit Records");
        AVDPrivatAPISetup.TestField("Next Page Parameter");

        if (StartingDate = '') or (EndingDate = '') then begin
            StartingDate := Format(CalcDate('<-1D>', Today), 0, '<Day,2>-<Month,2>-<Year4>');
            EndingDate := Format(Today, 0, '<Day,2>-<Month,2>-<Year4>');
        end;

        xURLTxt := StrSubstNo(AVDPrivatAPISetup."API Url", xIBAN,
                                StartingDate,
                                EndingDate,
                                AVDPrivatAPISetup."Limit Records");

        repeat
            URLTxt := xURLTxt;
            if NextPageExist then
                URLTxt := StrSubstNo(AVDPrivatAPISetup."Next Page Parameter", xURLTxt, NextPageURI);
            Response := Connect2Privat(URLTxt, IsSuccessStatus);

            // Logging responce
            PrivatLogging(Response, AVDPrivatAPILog);

            // Parse responce
            if IsSuccessStatus then begin
                ClearLastError();
                if not GetNextPage(AVDPrivatAPILog, NextPageURI, NextPageExist) then
                    Message(GetLastErrorText());
            end;
            if not xAllStatistic then exit(true);
        until not NextPageExist;

        exit(true);
    end;

    procedure Connect2Privat(xURLTxt: Text; var xIsSuccessStatus: Boolean): Text
    var
        client: HttpClient;
        requestMessage: HttpRequestMessage;
        responseMessage: HttpResponseMessage;
        headers: HttpHeaders;
        responseText: Text;
        requestText: Text;
        // APIIsOkLbl: Label 'API is Ok!';
        lblRequestMethod: Label 'GET', Locked = true;
        lblContentType: Label 'Content-Type', Locked = true;
        content: HttpContent;
        contentHeaders: HttpHeaders;
        StartRequest: DateTime;
        requestDuration: Duration;
    begin
        requestMessage.SetRequestUri(xURLTxt);
        // Setup the HTTP Verb
        requestMessage.Method := lblRequestMethod;

        requestMessage.Content := content;
        requestMessage.Content.GetHeaders(contentHeaders);
        if contentHeaders.Contains(lblContentType) then contentHeaders.Remove(lblContentType);
        contentHeaders.Add(lblContentType, AVDPrivatAPISetup."Content Type");

        // Add some request headers like:
        requestMessage.GetHeaders(headers);
        headers.Add(AVDPrivatAPISetup."Client ID Key", AVDPrivatAPISetup."Client ID");
        headers.Add(AVDPrivatAPISetup."Token Key", AVDPrivatAPISetupLine.Token);
        // headers.Add('Accept', '*/*');

        // Send the message
        StartRequest := CurrentDateTime;
        client.Send(requestMessage, responseMessage);
        requestDuration := CurrentDateTime - StartRequest;
        responseMessage.Content.ReadAs(responseText);
        // Return the Status Code
        xIsSuccessStatus := responseMessage.IsSuccessStatusCode;
        // log request
        LogIntegrationMgt.InsertOperationToLog('PRIVAT', requestMessage.Method, xURLTxt, AVDPrivatAPISetup."Client ID",
                                                BankAccount."No.", responseText, xIsSuccessStatus, requestDuration);

        exit(responseText);
    end;

    local procedure GenJnlLineOnCreating(xAVDPrivatAPILog: Record "AVD Privat API Log"; var xNextPageURI: Text; var xNextPageExist: Boolean)
    begin
        GenJnlLineOnInsert(xAVDPrivatAPILog, false);
        Message('Done!');
    end;

    local procedure PrivatLogging(xJsonObjectAsText: Text; var AVDPrivatAPILog: Record "AVD Privat API Log")
    var
        ObjectJSONManagement: Codeunit "JSON Management";
    begin
        ObjectJSONManagement.InitializeObject(xJsonObjectAsText);
        xJsonObjectAsText := ObjectJSONManagement.WriteObjectToString();

        AVDPrivatAPILogOnInitInsert(AVDPrivatAPILog, xJsonObjectAsText);
    end;

    [TryFunction]
    local procedure PreviewRunCheck(var xtempGenJnlLine: Record "Gen. Journal Line" temporary)
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        GenJnlCheckLine.RunCheck(xtempGenJnlLine);
    end;

    // [TryFunction]
    local procedure PostRunWithCheck(var xGenJnlLine: Record "Gen. Journal Line"; var xErrorText: Text): Boolean
    var
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        Clear(xErrorText);
        if not Codeunit.Run(Codeunit::"Gen. Jnl.-Post Line", xGenJnlLine) then
            xErrorText := GetLastErrorText();
        exit(xErrorText = '');
    end;

    local procedure AVDPrivatAPILogOnInitInsert(var xAVDPrivatAPILog: Record "AVD Privat API Log"; xJsonObjectAsText: Text)
    begin
        xAVDPrivatAPILog.LockTable();
        xAVDPrivatAPILog.Init();
        xAVDPrivatAPILog.ID := 0;
        xAVDPrivatAPILog."Bank Acc. No." := BankAccount."No.";
        xAVDPrivatAPILog.Insert(true);
        xAVDPrivatAPILog.SetContent(xJsonObjectAsText);
        xAVDPrivatAPILog.UpdateLineCount();
        Commit();
    end;

    local procedure PrivatOnProcess()
    begin
        AVDPrivatAPISetupLine.SetCurrentKey(Blocked);
        if BankAccNoFilter.Trim() <> '' then
            AVDPrivatAPISetupLine.SetFilter("Bank Acc. No.", BankAccNoFilter);
        AVDPrivatAPISetupLine.SetRange(Blocked, false);
        if AVDPrivatAPISetupLine.FindSet() then begin
            repeat
                GetBankAccount(AVDPrivatAPISetupLine."Bank Acc. No.");
                BankAccount.TestField(IBAN);
                BankAccount.TestField("SMA EDRPOU Code");
                PrivatTransactionsOnGet(BankAccount.IBAN, true);
            until AVDPrivatAPISetupLine.Next() = 0;
            AVDPrivatJobQueue.EnqueueJobEntry();
        end;
        ClearGlobalVariables();
    end;

    local procedure GetNewGenJnlLineNo(var xGenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        if (xGenJnlLine."Journal Template Name" = '') or (xGenJnlLine."Journal Batch Name" = '') then exit;

        GenJnlLine.SetRange("Journal Template Name", xGenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", xGenJnlLine."Journal Batch Name");
        if GenJnlLine.FindLast() then
            xGenJnlLine."Line No." := GenJnlLine."Line No." + 10000
        else
            xGenJnlLine."Line No." := 10000;

    end;

    local procedure SetNewDateFilter()
    var
        SetManualDateFilter: Page "AVD Manual Date Filter";
    begin
        ClearGlobalVariables();
        CloseActionOk := SetManualDateFilter.RunModal() = Action::OK;
        SetManualDateFilter.GetManualDateFilter(StartingDate, EndingDate, BankAccNoFilter);
    end;

    local procedure GetBankAccount(xBankAccNo: Code[20])
    begin
        BankAccount.Get(xBankAccNo);
    end;

    local procedure ClearGlobalVariables()
    begin
        Clear(BankAccNoFilter);
        Clear(StartingDate);
        Clear(EndingDate);
    end;

    internal procedure PrivatOnProcessWithManualDateFilter()
    begin
        SetNewDateFilter();
        if CloseActionOk then
            PrivatOnProcess();
    end;

    internal procedure GetSetupLine(AVDPrivatAPILog: Record "AVD Privat API Log"): Boolean
    begin
        AVDPrivatAPILog.TestField("Bank Acc. No.");
        AVDPrivatAPISetupLine.Get(AVDPrivatAPILog."Bank Acc. No.");
        exit(BankAccount.Get(AVDPrivatAPILog."Bank Acc. No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempGenJnlLineFromJson(var tempGenJnlLine: Record "Gen. Journal Line" temporary; xJsonObjectText: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempFAJnlLineFromJson(var tempFAJnlLine: Record "FA Journal Line" temporary; xJsonObjectText: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempItemJnlLineFromJson(var tempItemJnlLine: Record "Item Journal Line" temporary; xJsonObjectText: Text; var IsHandled: Boolean)
    begin
    end;

    var
        Window: Dialog;
        AVDPrivatAPISetup: Record "AVD Privat API Setup";
        AVDPrivatAPISetupLine: Record "AVD Privat API Setup Line";
        LogIntegrationMgt: Codeunit "AVD Log Integration Mgt.";
        AVDPrivatJobQueue: Codeunit "AVD Privat Job Queue";
        BankAccount: Record "Bank Account";
        DimMgt: Codeunit DimensionManagement;
        ChooseJSONFile: Label 'Choose JSON File';
        JSONEXt: Label '*.json*|*.*', Locked = true;
        Text005: Label 'Journal Template %1 Lines creating...\\';
        Text006: Label 'Creating temporary journal lines... #1############################\\';
        Text007: Label 'Creating journal lines...           #2############################\\';
        Text010: Label '%1 from %2';
        lblDone: Label 'Done!';
        lblUndefinedJournalType: Label 'Undefined Journal Type %1!';
        errPostedDocumentFound: Label 'Posted Document Type %1 Document No. %2 Posting Date %3 already exist!';
        errDocumentAlreadyExist: Label 'Document Type %1 Document No. %2 Posting Date %3 already exist!';
        StartingDate, EndingDate : Text[20];
        BankAccNoFilter: Text[250];
        CloseActionOk: Boolean;
        AVDPrivatAPISetupRead: Boolean;
        errCantFindCustomerByLoginID: Label 'Can`t Find Customer By Login ID %1';
        errCantFindLoginIDInPaymentAssignment: Label 'Can`t Find Login ID in Payment Assignment %1';
        errCantFindAssinedPayment: Label 'Can`t Find Assined Payment';
        errCantFindVendorByRegistrationNumber: Label 'Can`t Find Vendor By %1 %2';
        errCantFindCustomerByRegistrationNumber: Label 'Can`t Find Customer By %1 %2';
        errCantFindEDRPOU: Label 'Can`t Find EDRPOU in %1';
        errIncorrectPaymentForOwnership: Label 'Incorrect payment for ownership %1';
        AlreadyExistLbl: Label 'already exist!';
        AlreadyExistCounter: Integer;
}