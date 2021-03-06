This is a collection of tools to create a nested view of mathematical proofs.
It consists of 
- latex packages for producing symantically enhanced tex documents (for a more profound approach on semantic TeX see for example
[sTeX](https://trac.kwarc.info/sTeX/wiki) )
- a ruby script that generates separate pdf files for all sections, definitions and references
- a pdf viewer that assembles a collection of pdfs in a nested view (based on [pdf.js](https://github.com/mozilla/pdf.js/) )

### Online demo
- [http://surgery-hotel.de/nestedmath/viewer.html](http://surgery-hotel.de/nestedmath/viewer.html)
- [http://surgery-hotel.de/web/viewer.html](http://surgery-hotel.de/web/viewer.html)

### Usage
- [Download](https://github.com/xithan/nestedmath/archive/master.zip) this github repository.
- Edit `tex/example.tex` or adjust the paths at the top of `typeset.rb`
- Install [node.js](http://nodejs.org/)
- Run 

```
ruby typeset.rb
cd pdfviewer
node make server
```
- Open your browser and go to `localhost:8888/web/viewer.html`
