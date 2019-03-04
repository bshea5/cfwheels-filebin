<h1>CFWheels File Bin</h1>
<p>CFWheels Plugin to simplify file operations by providing a general /bin for file uploads and nested bins.</p>
<p></p>
<h2>Usage</h2>
<pre><code>&lt;cfscript&gt;
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
&lt;/cfscript&gt;
</code></pre>

