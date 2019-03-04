<cfscript>
	// allowed MIME types for file uploads
	allowedUploadMimeTypes = {
		"application/vnd.openxmlformats-officedocument.presentationml.presentation": {
			"extension": "pptx"
		},
		"application/vnd.openxmlformats-officedocument.wordprocessingml.document": {
			"extension": "docx"
		},
		"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": {
			"extension": "xlsx"
		},
		"application/vnd.ms-xpsdocument": {
			"extension": "xps"
		},
		"application/vnd.ms-excel": {
			"extension": "xls"
		},
		"application/msword": {
			"extension": "doc"
		},
		"application/pdf": {
			"extension": "pdf"
		},
		"text/plain": {
			"extension": "txt"
		},
		"text/html": {
			"extension": "html"
		},
		"application/rtf": {
			"extension": "rtf"
		},
		"text/richtext": {
			"extension": "rtx"
		},
		"image/jpeg": {
			"extension": "jpg"
		},
		"image/jpeg": {
			"extension": "jpeg"
		},
		"image/gif": {
			"extension": "gif"
		},
		"image/png": {
			"extension": "png"
		},
		"application/zip": {
			"extension": "zip"
		}
	};
</cfscript>