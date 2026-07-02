11. **Finish the plus proposal workflow**

    Show summary:
    - Change name and location
    - List of artifacts created
    - Validation result
    - Final plus review decision

    Do not move the change out of `openspec/changes/`.

    The plus proposal workflow ends with the active change still available for implementation.

    If the user wants to temporarily set the change aside, they can do that manually after this workflow ends.

    Inform the user:
    - The change remains active.
    - The plus quality gate has completed or aborted with a recorded round file.
    - Running `/spectra-apply <change-name>` or `/spectra-apply-plus <change-name>` later can start implementation.

    If the current environment has a separate planning mode, also remind the user to switch the session to normal mode before running an apply workflow. This is only a reminder: do NOT try to switch modes with any tool, do NOT ask whether to switch modes, and do NOT invoke apply.

    The propose-plus workflow ENDS here.

    Do NOT invoke `/spectra-apply`.

    Do NOT call **AskUserQuestion** to ask whether to apply.

    Do NOT run any command that parks the change.

    This behavior is identical across Auto Mode, interactive mode, and any other agent mode.

    The end state is explicit: artifacts exist, validation has run, review records exist, and the change remains active.
