Include "${SHELLSPEC_PROJECT_ROOT}/bin/manage_bash_history.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/spec/bin/manage_bash_history/spec_helper.sh"

Describe '_get_filtered_global_commands_stdout function'
  # This helper function uses its own mktemp call internally for "bash_unique_hist.XXXXXX"
  BeforeEach 'setup_test_environment' 'mock_helper_unique_hist_mktemp_command'
  AfterEach 'unmock_mktemp_command' 'teardown_test_environment'


  # label | histfile_content_csv | patterns_content_csv | expected_output_csv
  Parameters
    '#1: Basic filter'  'global1,commonA,global2,commonB' 'commonA,commonB' 'global1,global2'
    '#2: No patterns'   'global1,global2'                 ''                'global1,global2'
    '#3: Empty histfile' ''                               'commonA'         ''
    '#4: All filtered'  'commonA,commonB'                 'commonA,commonB' ''
    '#5: Duplicates in histfile' 'g1,g2,g1,g3'            ''                'g1,g2,g3'
    '#6: Patterns not in histfile' 'g1,g2'                'commonX'         'g1,g2'
  End

  It "filters global commands: case ${1} (hist:'${2}' patterns:'${3}' -> out:'${4}')"
    patterns_file_for_filter="${TEST_TMPDIR}/patterns_for_filter.txt"

    hist_lines=($(echo "$2" | tr ',' '\n'))
    # Ensure HISTFILE is empty before populating for this test iteration
    >"${HISTFILE}"
    for line in "${hist_lines[@]}"; do
      # Avoid adding empty lines if CSV ends with comma or has empty segments for histfile.
      if [ -n "$line" ]; then echo "$line" >> "${HISTFILE}"; fi
    done
    patterns_lines=($(echo "$3" | tr ',' '\n'))
    >"${patterns_file_for_filter}"
    for line in "${patterns_lines[@]}"; do
      if [ -n "$line" ]; then echo "$line" >> "${patterns_file_for_filter}"; fi
    done
    # If patterns_content_csv is empty, patterns_file_for_filter will be empty.
    # If patterns_content_csv is truly not set (e.g. from an older test), handle path as empty string.
    local current_patterns_file_path="$patterns_file_for_filter"
    if [ -z "$3" ]; then
        current_patterns_file_path=""
    fi

    When call _get_filtered_global_commands_stdout "${HISTFILE}" "${current_patterns_file_path}"
    The status should be success

    expected_output_lines=($(echo "$4" | tr ',' '\n'))

    get_expected_output() {
      for eline in "${expected_output_lines[@]}"; do
        if [ -n "$eline" ]; then echo "${eline}"; fi # Avoid extra newline for empty expected output
      done
    }

    if [ ${#expected_output_lines[@]} -eq 0 ] || [ -z "$4" ] ; then
      The output should equal ""
    else
      The output should equal "$(get_expected_output)"
    fi
    # _mock_helper_unique_history_path is the mocked path for the internal temp file
    # Check if it was cleaned up, but only if HISTFILE existed (otherwise mktemp isn't called)
    if [ -f "${HISTFILE}" ] && [ -s "${HISTFILE}" ]; then
        The path "${_mock_helper_unique_history_path}" should not be exist
    fi
  End

  It 'handles mktemp failure for its internal unique_hist file gracefully'
    # Override the helper mktemp mock to simulate failure for "bash_unique_hist"
    unmock_mktemp_command # Remove default helper mock from BeforeEach
    mktemp() {
      local template_prefix
      template_prefix=$(echo "$1" | sed "s/\.XXXXXX//")
      if [ "${template_prefix}" = "bash_unique_hist" ]; then
        echo ""  # Simulate mktemp failure by returning empty string
        return 1
      else  # Fallback for any other unexpected mktemp calls
        command mktemp "$@" --tmpdir="${TEST_TMPDIR}"
      fi
    }

    echo "some_command" > "${HISTFILE}"  # Ensure HISTFILE exists to trigger the mktemp call

    When call _get_filtered_global_commands_stdout "${HISTFILE}" ""
    The status should equal 1
    The error should include "Error: Helper: Failed to create temporary file"
    The output should equal ""
  End
End
