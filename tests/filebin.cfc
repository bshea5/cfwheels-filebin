component extends="wheels.Test"  hint="Unit Tests" {
    /**
	 * Executes once before this package's first test case.
     * 
     * Create a bin for test to be performed. This will make it easier to 
     * clean up afterwards.
	 */
	function packageSetup() {
        _testbin_ = bin("testbincreatedbytestcase", true);
	}

    /**
	 * Executes once after this package's last test case.
	 */
	function packageTeardown() {
        directoryDelete(_testbin_._path_, true);

        if (fileExists("testfileobj"))
            fileDelete("testfileobj");
    }
    
    /**
	 * Executes before every test case.
	 */
	function setup() {
        _fileObjInBin_ = $createValidTestFile("TestBin.txt"); 
        _fileObjInTemp_ = $createTempTestFile("TestTemp.txt");
    }
    
    /**
	 * Executes after every test case.
	 */
	function teardown() {
        if (fileExists(_fileObjInBin_.path))
            fileDelete(_fileObjInBin_.path);
        if (fileExists(_fileObjInTemp_.path))
            fileDelete(_fileObjInTemp_.path);
	}


	function Test_Default_Bin_Creation() {
        defaultbin = bin();
        assert('directoryExists(defaultbin._path_)');
    }

    function Test_New_Bin_Creation() {
        assert('directoryExists(_testbin_._path_)');
        assert('_testbin_._path_ EQ expandPath("/files/bin/testbincreatedbytestcase")');
    }

    // Only test upload operation, delete operation will be tested else where.
    // Not sure how to test this without a cfform...
    // function Test_File_Upload_And_Immigrate_To_Bin() {
    //     fpath = _testbin_._path_ & _testbin_.upload($createValidTestFile());
    //     assert('fileExists(fpath)');
    //     fileDelete(fpath);
    //     assert('!fileExists(fpath)');
    // }

    function Test_Immigrate_File_Into_Bin() {
        filename = _testbin_.immigrate(_fileObjInBin_);
        fullpath = "#_testbin_._path_#/#filename#";

        assert('fileExists(fullpath)');
        fileDelete(fullpath);
        assert('!fileExists(fullpath)');
    }

    function Test_Immigrate_File_Into_Bin_With_Custom_Mime_FAIL() {
        // 1st, lets get one to fail for a bad mime type
        allowedUploadMimeTypes = {
            "application/pdf": {
                "extension": "pdf"
            }
        };

        customBin = bin(mimes = allowedUploadMimeTypes);

        try {
            filename = customBin.immigrate(_fileObjInTemp_);
            fullpath = "#customBin._path_#/#filename#";

            fileDelete(fullpath);
            assert('false');
        } catch (any e) {
            _e_ = e; // re-declare e in new var so it can be used in assert()
            assert('_e_.errorCode EQ 415');
        }
    }

    function Test_Immigrate_File_Into_Bin_With_Custom_Mime_PASS() {
        // 1st, lets get one to fail for a bad mime type
        allowedUploadMimeTypes = {
            "text/plain": {
                "extension": "txt"
            }
        };

        customBin = bin(mimes = allowedUploadMimeTypes);

        filename = customBin.immigrate(_fileObjInTemp_);
        fullpath = "#customBin._path_#/#filename#";

        assert('fileExists(fullpath)');
        fileDelete(fullpath);
        assert('!fileExists(fullpath)');
    }

    // bin upload will be tested else where, only test deletion here
    function Test_Deleting_File_In_Bin() {
        path2Check = _fileObjInBin_.path;
        _testbin_.delete(_fileObjInBin_.name);
        assert('!fileExists(path2Check)');
    }

    function Test_Mime_Check() {
        mime = _testbin_.mimeext(_fileObjInBin_);
        assert(' mime EQ "txt" ');

        mime = _testbin_.mimeext("test");
        assert(' mime EQ "" ');
    }

    function Test_Zipping_Files() {
        zippedFilePath = _testbin_.zip("#_fileObjInBin_.name#,#_fileObjInBin_.name#", "foo");
        debug("zippedFilePath", true);
        assert('fileExists(zippedFilePath)');

        mime = fileGetMimeType(zippedFilePath, true);
        assert(' mime EQ "application/zip" ');
    }

    function Test_Zipping_Files_To_RAM() {
        zippedFilePath = _testbin_.zip("#_fileObjInBin_.name#,#_fileObjInBin_.name#", "foo", true);
        debug("zippedFilePath", true);
        assert('fileExists(zippedFilePath)');

        mime = fileGetMimeType(zippedFilePath, true);
        assert(' mime EQ "application/zip" ');
    }

    // Create a valid file for testing, return the file object.
    // Make sure opened files are closed! They don't need to be open in order to
    // be processed, but leaving them open will cause locks to be left in place.
    any function $createValidTestFile(required string filename) {
        FileWrite("testfileobj", "This is a test!");

        f = FileRead("testfileobj");
        fpath = _testbin_._path_ & '/' & filename;

        FileWrite("#fpath#", "#f#"); 
        assert('fileExists(fpath)');

        var fileObj = FileOpen(fpath, "read"); 
        fileClose(fileObj);
        return fileObj;
    }

    any function $createTempTestFile(required string filename) {
        tempDir = GetTempDirectory();

        FileWrite("testfileobj", "This is a temp test!");

        f = FileRead("testfileobj"); 
        fpath = tempDir & '/' & filename;

        FileWrite("#fpath#", "#f#"); 
        assert('fileExists(fpath)');

        var fileObj = FileOpen(fpath, "read"); 
        fileClose(fileObj);
        return fileObj;
    }
}
