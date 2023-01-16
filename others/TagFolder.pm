package LANraragi::Plugin::Metadata::TagFolder;

use strict;
use warnings;

#Plugins can freely use all Perl packages already installed on the system
#Try however to restrain yourself to the ones already installed for LRR (see tools/cpanfile) to avoid extra installations by the end-user.
use File::Basename;

#You can also use the LRR Internal API when fitting.
use LANraragi::Model::Plugins;
use LANraragi::Utils::Database qw(redis_encode redis_decode);
use LANraragi::Utils::Logging qw(get_logger);

#Meta-information about your plugin.
sub plugin_info {

    return (
        #Standard metadata
        name      => "Use foldername as tag",
        type      => "metadata",
        namespace => "tagfolder",
        author    => "Ftbom",
        version   => "1.0",
        description =>
          "Generate the tag from the folder's name.",
        icon =>
          "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAL1JREFUOI1jZMABpNbH/sclx8DAwPAscDEjNnEMQUIGETIYhUOqYdgMhTPINQzdUEZqGIZsKBM1DEIGTOiuexqwCKdidDl0vtT62P9kuZCJEWuKYWBgYGBgRHbh04BFDNIb4jAUbbSrZTARUkURg6lD10OUC/0PNaMYgs1Skgwk1jCSDCQWoBg46dYmhite0+D8pwGLCMY6uotRDOy8toZBkI2HIhcO/pxCm8KBUkOxFl/kGoq3gCXFYFxVAACeoU/8xSNybwAAAABJRU5ErkJggg==",
        parameters => [ { type => "string", desc => "The category of tag" } ] #plugin设置
    );

}

#Mandatory function to be implemented by your plugin
sub get_tags {

    shift;
    my $lrr_info = shift;    # Global info hash
    my ($category) = @_;    # Plugin parameters

    my $logger = get_logger( "tagfolder", "plugins" );
    my $file   = $lrr_info->{file_path}; #完整文件地址
    my $tagstring;

    # lrr_info's file_path is taken straight from the filesystem, which might not be proper UTF-8.
    # Run a decode to make sure we can derive tags with the proper encoding.
    $file = redis_decode($file);

    # Get the filename from the file_path info field
    my ( $filename, $filepath, $suffix ) = fileparse( $file, qr/\.[^.]*/ );

    $_ = "$filepath"; #获取文件地址
    if (/\/([^\/]+)\/$/)
    {
        $tagstring="$category:$1"; #上级目录作tag名
    }
    $logger->debug( "Sending the following tags to LRR: " . $tagstring );
    return ( tags => $tagstring );

}
1;
