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

EncodingSampler determines collects a reasonably (but not rigorously) minimal sample by reading the file line-by-line, dismissing encodings that are invalid, and collecting a sample of (binary) lines where different encodings yield different results.  Each pair of encodings is considered identical until a line is found that translates differently between the two encodings.  When the sampling is complete, all the encodings are grouped with other encoding(s) yield identical decoding results.

When sampling is complete, there are three possible results:
* There may be no valid encodings.  This could mean that none of the proposed encodings match the file, but often it means the file is simply malformed.  This is generally what you will see if you try to determine the encoding of a non-text binary file.
* There may be only one group of valid encodings, all of which yield the same decoded data.  In this case there are no samples to look at because there are no encodings to differentiate between.
* There may be more than one set of valid encodings, each if which yields a different decoded data.  In this case the samples are available so a user can determine which is the correct interpretation.

## Performance

Because this method works by reading file lines and "decoding" each line with all the remaining valid encodings, it can be slow. Starting with a broad range of valid encodings can make it slower.  At this writing, Ruby 1.9.2 supports 164 encodings!  It's recommended to try and use a much smaller set.

## Installation

Add this line to your application's Gemfile:

    gem 'encoding_sampler'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install encoding_sampler

## Usage

Creating a new EncodingSampler instantiates a new instance and completes the file analysis.

    EncodingSampler.new(file_name, options = {}} → new_encoding_sampler
    
    options:
      :difference_start => 
      :difference_end =>

Once you have an instance of an EncodingSampler, you can use the objects instance methods to determine which encodings are valid, which are unique (that is, which yeield unique results,) and get samples to compare the differences visually.  For example, imagining you have a file that turns out to be ISO-8859-15 (which includes the Euro sign,) you might bet these results:

    sampler = EncodingSampler.new('some/file.txt', ['ASCII-8BIT', 'ISO-8859-1', 'ISO-8859-15', 'WINDOWS-1252', 'UTF-8'])

    #Create a sampler:

    irb(main):001:0> sampler = EncodingSampler::Sampler.new(Rails.root.join('spec/fixtures/file_encoding_survey_test_files/ISO-8859-15.txt').to_s, ['ASCII-8BIT', 'UTF-8', 'ISO-8859-1', 'ISO-8859-15'])
    => #<EncodingSampler::Sampler:0x007f979592ea30 @diff_options={}, @filename="/Users/tomwilson/rollnorocks/aptana_workspace/t2s-admin/spec/fixtures/file_encoding_survey_test_files/ISO-8859-15.txt", @binary_samples={1=>"\xA4ABCDEFabcdef0123456789\xA4ABCDEFabcdef0123456789\xA4"}, @unique_valid_encodings=[["ASCII-8BIT"], ["ISO-8859-1"], ["ISO-8859-15"]]>

    # Query for valid and unique encodings:    

    irb(main):002:0> sampler.valid_encodings
    => ["ASCII-8BIT", "ISO-8859-1", "ISO-8859-15"]

    irb(main):003:0> sampler.unique_valid_encodings
    => [["ASCII-8BIT"], ["ISO-8859-1"], ["ISO-8859-15"]]

    # Now the payoff.  Samples for each encoding:

    irb(main):004:0> sampler.sample('ASCII-8BIT')
    => ["?ABCDEFabcdef0123456789?ABCDEFabcdef0123456789?"]

    irb(main):005:0> sampler.sample('ISO-8859-1')
    => ["¤ABCDEFabcdef0123456789¤ABCDEFabcdef0123456789¤"]

    irb(main):006:0> sampler.sample('ISO-8859-15')
    => ["€ABCDEFabcdef0123456789€ABCDEFabcdef0123456789€"]

    # Or you can request them all at once:

    irb(main):016:0> sampler.samples(["ASCII-8BIT", "ISO-8859-1", "ISO-8859-15"])
    => {"ASCII-8BIT"=>["?ABCDEFabcdef0123456789?ABCDEFabcdef0123456789?"], 
      "ISO-8859-1"=>["¤ABCDEFabcdef0123456789¤ABCDEFabcdef0123456789¤"], 
      "ISO-8859-15"=>["€ABCDEFabcdef0123456789€ABCDEFabcdef0123456789€"]}

    # Finally, you can "diff" the results so it's easy to see the differences.  
    # (This looks like a mess here, but included in an html page with proper CSS, 
    # it displays the results in a way that highlights the differences.)

    irb(main):005:0> sampler.diffed_samples(["ASCII-8BIT", "ISO-8859-1", "ISO-8859-15"])
    => {"ASCII-8BIT"=>["<span class=\"difference\">?</span>ABCDEFabcdef0123456789<span class=\"difference\">?</span>ABCDEFabcdef0123456789<span class=\"difference\">?</span>"], 
    "ISO-8859-1"=>["<span class=\"difference\">¤</span>ABCDEFabcdef0123456789<span class=\"difference\">¤</span>ABCDEFabcdef0123456789<span class=\"difference\">¤</span>"], 
    "ISO-8859-15"=>["<span class=\"difference\">€</span>ABCDEFabcdef0123456789<span class=\"difference\">€</span>ABCDEFabcdef0123456789<span class=\"difference\">€</span>"]}
    irb(main):006:0>

For example, diffed samples could be displayed as:
<table>
<tr>
  <th>ASCII-8BIT</th>
  <td><span style='color:red;font-weight:bold;'>?</span>ABCDEFabcdef0123456789<span style='color:red;font-weight:bold;'>?</span>ABCDEFabcdef0123456789<span style='color:red;font-weight:bold;'>?</span></td>
</tr>
<tr>
  <th>ISO-8859-</th>
  <td><span style='color:red;font-weight:bold;'>¤</span>ABCDEFabcdef0123456789<span style='color:red;font-weight:bold;'>¤</span>ABCDEFabcdef0123456789<span style='color:red;font-weight:bold;'>¤</span></td>
</tr>
  <th>ISO-8859-15</th>
  <td><span style='color:red;font-weight:bold;'>€</span>ABCDEFabcdef0123456789<span style='color:red;font-weight:bold;'>€</span>ABCDEFabcdef0123456789<span style='color:red;font-weight:bold;'>€</span></td>
</tr>
</table>

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
