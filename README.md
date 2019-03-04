# CFWheels File Bin

## Description

CFWheels Plugin to simplify file operations by providing a general /bin for file uploads and nested bins.

## Usage
```
    // sample function for uploading a file parameter
    /**
     * filter to handle file uploading
     * 
     * [section: Controller helpers]
     * [category: Controller Functions]
     * 
     * @file
     */
    private string function uploadfileparam() {
        try {
            // initialize a bin using the default directory(no args)
            // than upload the file parameter
            params.filename = bin().upload(params.file);
        } catch (any e) {
            resp.errors = e.message;
            resp.status = e.errorCode NEQ '' ? e.errorCode : 500;
            sendResponse();
        } 
    }
```

## Allowed MIME Types

Allowed MIME Types are defined in mimetypes.cfm. You can override this by modifying the file directly, are passing in your defined mime types as a bin() arg.

## Bin Directory

The plugin's first init call will create the files/bin directory if it doesn't already exist.
