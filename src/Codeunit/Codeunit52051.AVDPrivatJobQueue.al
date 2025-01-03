codeunit 52051 "AVD Privat Job Queue"
{
    Permissions = tabledata "Job Queue Entry" = rimd,
                    tabledata "AVD Privat API Log" = rimd,
                    tabledata "Job Queue Category" = rimd;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        AVDPrivatAPILogOnProcess();
    end;

    procedure EnqueueJobEntry(): Guid
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        Clear(JobQueueEntry.ID);
        if not AVDPrivatAPILog.WritePermission then begin
            if JobQueueEntry.IsReadyToStart() then
                JobQueueEntry.Restart();
            exit(JobQueueEntry.ID);
        end;

        if JQEIsExist(JobQueueEntry) then exit(JobQueueEntry.ID);

        if JQEIsError(JobQueueEntry) then begin
            JobQueueEntry.Restart();
            exit(JobQueueEntry.ID);
        end;

        JobQueueEntry.Reset();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"AVD Privat Job Queue";
        JobQueueEntry."Job Queue Category Code" := GetJobQueueLogProcessCategoryCode();
        JobQueueEntry.Description := lblLogProcessDescription;
        JobQueueEntry."User Session ID" := SessionId();
        // JobQueueEntry."Maximum No. of Attempts to Run" := 10;
        // JobQueueEntry."Rerun Delay (sec.)" := 5;
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
        exit(JobQueueEntry.ID)
    end;

    internal procedure GetJobQueueLogProcessCategoryCode(): Code[10]
    var
        JobQueueCategory: Record "Job Queue Category";
    begin
        JobQueueCategory.InsertRec(
            CopyStr(DefaultCategoryCodeLbl, 1, MaxStrLen(JobQueueCategory.Code)),
            CopyStr(DefaultCategoryDescLbl, 1, MaxStrLen(JobQueueCategory.Description)));
        exit(JobQueueCategory.Code);
    end;

    local procedure JQEIsExist(var JobQueueEntry: Record "Job Queue Entry"): Boolean
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"AVD Privat Job Queue");
        JobQueueEntry.SetRange("Job Queue Category Code", GetJobQueueLogProcessCategoryCode());
        // JobQueueEntry.SetRange(Description, lblLogProcessDescription);
        JobQueueEntry.SetFilter(Status, '%1|%2', JobQueueEntry.Status::Ready, JobQueueEntry.Status::"In Process");
        exit(JobQueueEntry.FindFirst());
    end;

    local procedure JQEIsError(var JobQueueEntry: Record "Job Queue Entry"): Boolean
    begin
        JobQueueEntry.SetFilter(Status, '%1', JobQueueEntry.Status::Error);
        exit(JobQueueEntry.FindFirst());
    end;

    internal procedure AVDPrivatAPILogOnProcess()
    var
        AVDPrivatAPILogMod: Record "AVD Privat API Log";
    begin
        AVDPrivatAPILog.SetCurrentKey("Company Name", Active);
        AVDPrivatAPILog.SetRange("Company Name", CompanyName);
        AVDPrivatAPILog.SetRange(Active, true);
        if AVDPrivatAPILog.FindSet(true) then
            repeat
                AVDPrivatAPIMgt.GenJnlLineOnInsert(AVDPrivatAPILog, false);
                AVDPrivatAPILog.Active := false;
                AVDPrivatAPILog.Modify();
                Commit();

                GetAVDPrivatAPISetup('');
                if AVDPrivatAPISetup."Post Line" then
                    AVDPrivatAPIMgt.GenJnlLineOnPost(AVDPrivatAPILog."Bank Acc. No.");

            until AVDPrivatAPILog.Next() = 0;
    end;

    local procedure GetAVDPrivatAPISetup(xClientID: Text[50])
    begin
        if AVDPrivatAPISetup.Count > 1 then
            AVDPrivatAPISetup.Get(xClientID)
        else
            AVDPrivatAPISetup.FindFirst();
    end;

    var
        AVDPrivatAPISetup: Record "AVD Privat API Setup";
        lblLogProcessDescription: Label 'AVD Privat Log Processor';
        DefaultCategoryCodeLbl: Label 'LOGPROCBCGR', Locked = true;
        DefaultCategoryDescLbl: Label 'Def. Background AVD Privat Log Processor', Locked = true;
        AVDPrivatAPILog: Record "AVD Privat API Log";
        AVDPrivatAPIMgt: Codeunit "AVD Privat API Mgt";
}