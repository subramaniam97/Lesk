import string
from itertools import chain

from nltk.corpus import wordnet as wn
from nltk.corpus import stopwords
from nltk import word_tokenize, pos_tag
from utils import lemmatize, porter, lemmatize_sentence, synset_properties
import allwords_wsd

EN_STOPWORDS = stopwords.words('english') + list(string.punctuation)

def compare_overlaps(context, synsets_signatures, \
                     nbest=False, keepscore=False, normalizescore=False):
    """
    Calculates overlaps between the context sentence and the synset_signture
    and returns a ranked list of synsets from highest overlap to lowest.
    """
    overlaplen_synsets = [] # a tuple of (len(overlap), synset).
    for ss in synsets_signatures:
        overlaps = set(synsets_signatures[ss]).intersection(context)
        overlaplen_synsets.append((len(overlaps), ss))

    # Rank synsets from highest to lowest overlap.
    ranked_synsets = sorted(overlaplen_synsets, reverse=True)

    # Normalize scores such that it's between 0 to 1.
    if normalizescore:
        total = float(sum(i[0] for i in ranked_synsets))
        ranked_synsets = [(i/total,j) for i,j in ranked_synsets]

    if not keepscore: # Returns a list of ranked synsets without scores
        ranked_synsets = [i[1] for i in sorted(overlaplen_synsets, \
                                               reverse=True)]

    if nbest: # Returns a ranked list of synsets.
        return ranked_synsets
    else: # Returns only the best sense.
        return ranked_synsets[0]

def simple_signature(ambiguous_word, pos=None, lemma=True, stem=False, \
                     hyperhypo=True, stop=True):
    """
    Returns a synsets_signatures dictionary that includes signature words of a
    sense from its:
    (i)   definition
    (ii)  example sentences
    (iii) hypernyms and hyponyms
    """
    synsets_signatures = {}
    for ss in wn.synsets(ambiguous_word):
        try: # If POS is specified.
            if pos and str(ss.pos()) != pos:
                continue
        except:
            if pos and str(ss.pos) != pos:
                continue
        signature = []
        # Includes definition.
        ss_definition = synset_properties(ss, 'definition')
        signature+=ss_definition
        # Includes examples
        ss_examples = synset_properties(ss, 'examples')
        signature+=list(chain(*[i.split() for i in ss_examples]))
        # Includes lemma_names.
        ss_lemma_names = synset_properties(ss, 'lemma_names')
        signature+= ss_lemma_names

        # Optional: includes lemma_names of hypernyms and hyponyms.
        if hyperhypo == True:
            ss_hyponyms = synset_properties(ss, 'hyponyms')
            ss_hypernyms = synset_properties(ss, 'hypernyms')
            ss_hypohypernyms = ss_hypernyms+ss_hyponyms
            signature+= list(chain(*[i.lemma_names() for i in ss_hypohypernyms]))

        # Optional: removes stopwords.
        if stop == True:
            signature = [i for i in signature if i not in EN_STOPWORDS]
        # Lemmatized context is preferred over stemmed context.
        if lemma == True:
            signature = [lemmatize(i) for i in signature]
        # Matching exact words may cause sparsity, so optional matching for stems.
        if stem == True:
            signature = [porter.stem(i) for i in signature]
        synsets_signatures[ss] = signature

    return synsets_signatures


def adapted_lesk(context_sentence, ambiguous_word, \
                pos=None, lemma=True, stem=True, hyperhypo=True, \
                stop=True, context_is_lemmatized=False, \
                nbest=False, keepscore=False, normalizescore=False):

    # Ensure that ambiguous word is a lemma.
    ambiguous_word = lemmatize(ambiguous_word)
    # If ambiguous word not in WordNet return None
    if not wn.synsets(ambiguous_word):
        return None
    # Get the signatures for each synset.
    ss_sign = simple_signature(ambiguous_word, pos, lemma, stem, hyperhypo)
    for ss in ss_sign:
        # Includes holonyms.
        ss_mem_holonyms = synset_properties(ss, 'member_holonyms')
        ss_part_holonyms = synset_properties(ss, 'part_holonyms')
        ss_sub_holonyms = synset_properties(ss, 'substance_holonyms')
        # Includes meronyms.
        ss_mem_meronyms = synset_properties(ss, 'member_meronyms')
        ss_part_meronyms = synset_properties(ss, 'part_meronyms')
        ss_sub_meronyms = synset_properties(ss, 'substance_meronyms')
        # Includes similar_tos
        ss_simto = synset_properties(ss, 'similar_tos')

        related_senses = list(set(ss_mem_holonyms+ss_part_holonyms+
                                  ss_sub_holonyms+ss_mem_meronyms+
                                  ss_part_meronyms+ss_sub_meronyms+ ss_simto))

        signature = list([j for j in chain(*[synset_properties(i, 'lemma_names')
                                             for i in related_senses])
                          if j not in EN_STOPWORDS])

    # Lemmatized context is preferred over stemmed context
    if lemma == True:
        signature = [lemmatize(i) for i in signature]
    # Matching exact words causes sparsity, so optional matching for stems.
    if stem == True:
        signature = [porter.stem(i) for i in signature]
    # Adds the extended signature to the simple signatures.
    ss_sign[ss]+=signature

    # Disambiguate the sense in context.
    if context_is_lemmatized:
        context_sentence = context_sentence.split()
    else:
        context_sentence = lemmatize_sentence(context_sentence)
    best_sense = compare_overlaps(context_sentence, ss_sign, \
                                    nbest=nbest, keepscore=keepscore, \
                                    normalizescore=normalizescore)
    return best_sense

if __name__ == "__main__":
    synonyms = []

    filepath = '/home/subbu/Desktop/MP/pylesk/senseval/Sval2.plain/Sval2.train.plain.txt'
    keypath = '/home/subbu/Desktop/MP/pylesk/senseval/Sval2.keys/Senseval2.key'

    keylist = []
    num = 0
    denom = 0

    with open(keypath) as kp:
        line = kp.readline()
        while line:
            tlist = line.split()
            tlist = tlist[2:]
            keylist.append(tlist)
            line = kp.readline()


    with open(filepath) as fp:
        line = fp.readline()
        while line:
            synset = allwords_wsd.disambiguateWithHead(line)
            try:
                s = synset[0][1].lemmas()[0].key()
                for x in keylist[denom]:
                    if x == s:
                        num += 1
                        break
            except:
                pass
            denom += 1
            line = fp.readline()
            print("Accuracy: ", num / denom)
