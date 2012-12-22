# EncodingSampler

EncodingSampler helps solve the problem of what to do when you don't know the character encoding of a file.
It was initially created tosolve the typical problem of selecting an appropriate encoding for an uploaded user
file where the user also has no idea of the encoding (or typically, even what "character encoding" means.)

For a given file, some encodings may be dismissed out of hand because they would result in invalid
characters or sequences.  However, in the general case you have to let the user see the differences and choose.
For example, it's easy to determine that an 8-bit character is _not_ encoded as US_ASCII because it is simply invalid, 
but it's impossible to tell whether the character __0xA4__ should be displayed as a 
generic currency symbol (&curren;) using ISO-8859-1 or as a Euro symbol (&euro;) using ISO-8859-15
without asking the user.

EncodingSampler determines which encodings collects a minimal sample by reading the file line-by-line, dismissing encodings that are invalid,
and collecting a sample of lines where different encodings yield different results.

When sampling is complete, there are three possible results:
* There may be no valid encodings.  This could mean that none of the proposed encodings match the file, 
but often it means the file is simply malformed.  This is generally what you will see if you try to 
determine the encoding of a non-text binary file.
* There may be only one valid encoding

It works by reading a file line-by line, collecting a minimum set of sample lines that will let a user
see the differences between the various proposed encodings.  The result is a Hash where:  
* keys are Arrays of names of apparently-equivalent encodings (that is, encodings that yield identical 
results for the specified file), and...
* values are arrays containing the minimum number of "decoded" strings (file lines) that will visually differentiate
the encodings.  
The values can be presented to a user to choose which os the intended encoding.

Because this method works by reading file lines and "decoding" each line with all the remaining valid encodings,
it can be slow.  In the general case where more than one encoding is syntactically valid, the entire file
must be read to find that there are no differences.  This happens a lot since a 7-bit ASCII file 
will generally (always?) be valid and produce identical results for all encodings.

there are 164!! for Ruby 1.9.2

## Installation

Add this line to your application's Gemfile:

    gem 'encoding_sampler'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install encoding_sampler

## Usage

    EncodingSampler.new(file_name, options = {}} → new_encoding_sampler
    
options:
  :difference_start => 
  :difference_end =>


Example:Say you have a file that contains one line

    EncodingSampler.samples('/fiel/name.here', ['US-ASCII', 'ISO-8859-1', 'ISO-8859-15' 'UTF-8'])
_yields..._
    {
      ['ISO-8859-1', 'ISO-8859-15'] => 'some lines here']
      ['ISO-8859-1', 'ISO-8859-15'] => 'some lines here']
    }

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
