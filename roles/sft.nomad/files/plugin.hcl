plugin "docker" {
	config {
		volumes {
			enabled = true
		}
		allow_privileged = true
	}
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}