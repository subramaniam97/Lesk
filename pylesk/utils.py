from nltk.corpus import wordnet as wn
from nltk.stem import PorterStemmer, WordNetLemmatizer
from nltk import pos_tag, word_tokenize

SS_PARAMETERS_TYPE_MAP = {'definition':str, 'lemma_names':list,
                          'examples':list,  'hypernyms':list,
                          'hyponyms': list, 'member_holonyms':list,
                          'part_holonyms':list, 'substance_holonyms':list,
                          'member_meronyms':list, 'substance_meronyms': list,
                          'part_meronyms':list, 'similar_tos':list}

porter = PorterStemmer()
wnl = WordNetLemmatizer()

def lemmatize(ambiguous_word, pos=None, neverstem=False,
              lemmatizer=wnl, stemmer=porter):
    """
    Tries to convert a surface word into lemma, and if lemmatize word is not in
    wordnet then try and convert surface word into its stem.

    This is to handle the case where users input a surface word as an ambiguous
    word and the surface word is a not a lemma.
    """
    if pos:
        lemma = lemmatizer.lemmatize(ambiguous_word, pos=pos)
    else:
        lemma = lemmatizer.lemmatize(ambiguous_word)
    stem = stemmer.stem(ambiguous_word)
    # Ensure that ambiguous word is a lemma.
    if not wn.synsets(lemma):
        if neverstem:
            return ambiguous_word
        if not wn.synsets(stem):
            return ambiguous_word
        else:
            return stem
    else:
        return lemma


def penn2morphy(penntag, returnNone=False):
    morphy_tag = {'NN':wn.NOUN, 'JJ':wn.ADJ,
                  'VB':wn.VERB, 'RB':wn.ADV}
    try:
        return morphy_tag[penntag[:2]]
    except:
        return None if returnNone else ''

def lemmatize_sentence(sentence, neverstem=False, keepWordPOS=False,
                       tokenizer=word_tokenize, postagger=pos_tag,
                       lemmatizer=wnl, stemmer=porter):
    words, lemmas, poss = [], [], []
    for word, pos in postagger(sentence.split()):
        pos = penn2morphy(pos)
        lemmas.append(lemmatize(word.lower(), pos, neverstem,
                                lemmatizer, stemmer))
        poss.append(pos)
        words.append(word)
    if keepWordPOS:
        return words, lemmas, [None if i == '' else i for i in poss]
    return lemmas

def synset_properties(synset, parameter):
    """
    Making from NLTK's WordNet Synset's properties to function.
    Note: This is for compatibility with NLTK 2.x
    """
    return_type = SS_PARAMETERS_TYPE_MAP[parameter]
    func = 'synset.' + parameter
    return eval(func) if isinstance(eval(func), return_type) else eval(func)()
