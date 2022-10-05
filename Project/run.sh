#!/bin/zsh

mkdir -p compiled images

# ############ Convert friendly and compile to openfst ############
for i in friendly/*.txt; do
	echo "Converting friendly: $i"
   python compact2fst.py  $i  > sources/$(basename $i ".formatoAmigo.txt").txt
done


# ############ convert words to openfst ############
for w in tests/*.str; do
	echo "Converting words: $w"
	python ./word2fst.py `cat $w` > tests/$(basename $w ".str").txt
done


# ############ Compile source transducers ############
for i in sources/*.txt tests/*.txt; do
	echo "Compiling: $i"
    fstcompile --isymbols=syms.txt --osymbols=syms.txt $i | fstarcsort > compiled/$(basename $i ".txt").fst
done

# ############ CORE OF THE PROJECT  ############

# Creation of metaphoneLN
    fstcompose compiled/step1.fst compiled/step2.fst | fstcompose - compiled/step3.fst | fstcompose - compiled/step4.fst | fstcompose - compiled/step5.fst |
    fstcompose - compiled/step6.fst | fstcompose - compiled/step7.fst | fstcompose - compiled/step8.fst | fstcompose - compiled/step9.fst |
    fstarcsort > compiled/metaphoneLN.fst

# Creation of invertMetaphoneLN
    fstinvert compiled/metaphoneLN.fst | fstarcsort > compiled/invertMetaphoneLN.fst

# ############ generate PDFs  ############
echo "Starting to generate PDFs"
for i in compiled/*.fst; do
	echo "Creating image: images/$(basename $i '.fst').pdf"
   fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
done



# ############ tests  ############

echo "Testing"

for w in compiled/t-*.fst; do
    fstcompose $w compiled/metaphoneLN.fst | fstshortestpath | fstproject --project_type=output |
    fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./syms.txt
done
