component hint = "bin and template operations for file io"
output = "false"
mixin = "global" {

    public
    function init() {
        this.version = "2.0";

        /*
            Essential directories for plugin to run
        */
        if (!directoryExists(expandPath("/files/"))) {
            directoryCreate("#expandPath("/")#files/");
        }
        if (!directoryExists(expandPath("/files/bin/"))) {
            directoryCreate("#expandPath("/files/")#/bin");
        }

        return this;
    }

    /**
     * Get default valid mimes defined in mimetypes.cfm
     *
     */
    public struct function $mimes() {
        include "mimetypes.cfm";
        return allowedUploadMimeTypes;
    };

    /**
     * Get file object by opening the file;
     * Closing to make sure stream isn't left open, locking files.
     * The file object persists, even if the stream is closed; Return that.
     */
    public any function $fileobj(required string filepath) {
        var fileobj = fileOpen(filepath);
        fileClose(fileobj);
        return fileobj;
    }

    /**
     * Confirm file is readable. Action take is determined by server engine.
     *
     * @file 
     */
    public boolean function $canReadFile(required file){
        return (get('serverName') EQ "Lucee") 
            ? $canReadFileLucee(file)
            : $canReadFileAdobe(file);
    }

    /**
     * Adobe has a func to check if a given arg is a file obj.
     *
     * @file 
     */
    public boolean function $canReadFileAdobe(required file) {
        return isFileObject(file);
    }

    /**
     * Confirm the file's path can be read using Java's file.io.
     * 
     * @file
     */
    public boolean function $canReadFileLucee(required file) {
        var filepath = file?.path ?: "";
        var myfile = createObject("java", "java.io.File");

        return myfile.init(JavaCast("string", filepath)).canRead();
    }

    /**
     * Wrapper for filemove(), as AdobeCF expects a file path while Lucee
     * expects a file obj.
     *
     * @file
     * @dest Path for files targeted destination.
     */
    public void function $fileMove(required file, required string dest) {
        var filearg = get('serverName') EQ "Lucee" ? file : file.path;
        fileMove(filearg, dest);
    }

    /**
     * Main entry for bin. actions
     * `upload()`, `delete()`, `immigrate()`, `mimeext()` 
     * 
     * [section: Plugins]
     * [category: bin]
     * 
     * @binname Name of directory to perform operations on in. This will default to the root bin/.
     * @initbin Flag true if you'd like the directory to be created if it doesn't currently exist.
     * @mimes Allow MIME types. This will default to those defined in mimetypes.cfm. Adhear to the format defined in that file if overriding.
     * @locktimeout Value passed to cflock's timeout parameter.
     */
    public any function bin(
        binname = "",
        initbin = false,
        mimes = $mimes(),
        locktimeout = 5
    ) {
        if (!directoryExists(expandPath("/files/bin/#binname#"))) {
            if (initbin) {
                directoryCreate("#expandPath("/files/bin")#/#binname#");
            } else {
                throw(
                    message =  "The given bin directory doesn't exist. Please flag it to be initiliazed or manually create the directory.",
                    type = "Directory Not Found"
                );
            }
        }

        local._path_ = ExpandPath("/files/bin/#binname#");

        /**
         * Get file extension for given file, according to its actual mime type.
         * 
         * @file
         */
        local.mimeext = function(required any file) {  
            if (!$canReadFile(file))
                return "";

            var mime = fileGetMimeType(file, true);
            return structKeyExists(mimes, "#mime#") 
                ? (mimes['#mime#']?.extension ?: "" ) : "";  
        };

        /**
         * Import targeted file to this bin.
         * 
         * @file
         */
        local.immigrate = function(required any file) {
            var ext = mimeext(file);

            if (ext EQ "")
                throw(
                    message="File's MIME type is not accepted.",
                    type="Invalid File", 
                    errorcode=415
                );

            // move it to target location with a UUID name 
            var filename = CreateUUID() & "." & ext;
    
            $fileMove(file, "#_path_#/#filename#");
    
            return filename;
        };


        /**
         * Upload given file safely, by uploading to temp directory,
         * verifying the MIME type before moving to bin.
         * 
         * @file
         */
        local.upload = function(required any file) {
            var resultFileName = "";
            var tempDir = GetTempDirectory();
            var tempFile = fileUpload(tempDir, "file", accept);

            if (structIsEmpty(tempFile))
                throw ("Failure to upload file.");

            tempFile = $fileobj(tempFile.SERVERDIRECTORY & "/" & tempFile.SERVERFILE);
            resultFileName = immigrate(tempFile);

            return resultFileName;
        };

        /**
         * Delete file with given filename.
         * 
         * @filename Name of file to delete
         */
        local.delete = function(required string filename) {
            if (!exists(filename)) throw (
                message = "Given file(#filename#) does not exist in #_path_#.",
                errorcode = 404,
                type = "FILE!EXIST"
            );

            fileDelete("#_path_ & '/' & filename#");
        };

        local.exists = function(required string filename) {
            return fileExists("#_path_ & '/' & filename#");
        };

        /**
         * Zip files according to list of filenames.
         * 
         * @filenames List of files to zip. Move these to some dir for zipping and place in bin or temp.
         * @zipname Name of resulting zipped directory.
         * @deletefile Delete src file after zipping.
         * @toram Flag for saving to ram or to current bin path.
         */
        local.zip = function(
            required string filenames, 
            required string zipname,
            boolean deletefile = false, 
            boolean toram = false
        ) {
            var dirToZip = _path_ & "zips" & zipname;
            var destination = toram 
                ? "ram://filebin/#zipname#.zip" 
                : "#_path_##zipname#.zip";

            // Remove dir if already exists, so we don't include pre-existing files.
            // Dir could exist already if it wasn't deleted with a previous zip attempt.
            if (directoryExists("#dirToZip#")) {
                directoryDelete("#dirToZip#", true);
            }

            directoryCreate("#dirToZip#");

            try {
                for (filename in filenames) {
                    if (exists(filename)) {
                        if (deletefile) {
                            fileMove("#_path_ #/#filename#", "#dirToZip#/#filename#");
                        } else {
                            fileCopy("#_path_ #/#filename#", "#dirToZip#/#filename#");
                        }
                    }
                }

                // check if we actually populated the directory with anything
                if (arrayLen(directoryList("#dirToZip#")) LT 1) {
                    throw(
                        message = "Unable to zip any of the given files. " &  
                        "This is probably because the given files couldn't be found. " &
                        "Contact your site admin. ",
                        errorcode = 404
                    );
                }
    
                cfzip(action="zip", source="#dirToZip#", file="#destination#", overwrite="true");
            } catch (any e) {
                // ensure directory we just created is always deleted.
                directoryDelete("#dirToZip#", true);
                throw(
                    message = e.message,
                    errorcode = e.errorcode
                );
            }

            directoryDelete("#dirToZip#", true);

            return destination;
        };

        return local;
    }
}