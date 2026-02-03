# Java home - cached to avoid spawning java_home on every shell
cache_init "java_home" "/usr/libexec/java_home -v 15" --no-source --extension txt
cache_get "java_home" JAVA_HOME --extension txt && export JAVA_HOME
